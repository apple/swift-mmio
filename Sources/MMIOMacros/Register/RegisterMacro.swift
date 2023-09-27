//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum RegisterMacro {}

extension RegisterMacro: ParsableMacro {
  static let baseName = "Register"
  static let labels = ["bitWidth"]

  struct Arguments: ParsableMacroArguments {
    var bitWidth: ExprSyntax

    init(arguments: [ExprSyntax]) {
      self.bitWidth = arguments[0]
    }
  }
}

extension RegisterMacro: MemberMacro {
  /// Expand an attached declaration macro to produce a set of members.
  ///
  /// - Parameters:
  ///   - node: The custom attribute describing the attached macro.
  ///   - declaration: The declaration the macro attribute is attached to.
  ///   - context: The context in which to perform the macro expansion.
  ///
  /// - Returns: the set of member declarations introduced by this macro, which
  /// are nested inside the `attachedTo` declaration.
  /// - Throws: any error encountered during macro expansion.
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let diagnostics = DiagnosticBuilder<Self>()

    guard let arguments = Self.parse(from: node, in: context) else {
      return []
    }

    guard
      let bitWidth = arguments.bitWidth.as(IntegerLiteralExprSyntax.self),
      let bitWidth = bitWidth.value
    else {
      context.diagnose(
        .init(
          node: arguments.bitWidth,
          message: diagnostics.argumentMustIntegerLiteral(label: "bitWidth")))
      return []
    }

    guard [8, 16, 32, 64].contains(bitWidth) else {
      fatalError("TODO")
    }

    // Can only applied to structs.
    let structDecl = declaration.as(
      StructDeclSyntax.self,
      diagnostics: diagnostics,
      context: context)
    guard let structDecl = structDecl else { return [] }

    // Walk all the members of the struct.
    var error = false
    var bitFields = [BitField]()
    for member in structDecl.memberBlock.members {
      // Each member must be a variable declaration.
      guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
        context.diagnose(
          .init(
            node: member.decl,
            message: diagnostics.onlyMemberVarDecls()))
        error = true
        continue
      }
      // Each variable declaration must be annotated with exactly one bitField
      // macro.
      guard let (attribute, kind) = variableDecl.hasAttribute(oneOf: BitFieldKind.allCases) else {
        // FIXME: add a fixme
        context.diagnose(
          .init(
            node: variableDecl,
            message: diagnostics.onlyBitFieldMemberVarDecls()))
        error = true
        continue
      }

      // Parse the arguments from the bitField macro.
      guard let arguments = BitFieldMacroArguments(kind: kind, from: attribute, in: context) else {
        error = true
        continue
      }

      // Grab the type of the variable declaration. Diagnostics will be emitted
      // by the handling of @attched(accessor) of the applied bitField macro.
      guard
        let binding = variableDecl.binding,
        let name = binding.pattern.as(IdentifierPatternSyntax.self),
        let type = binding.typeAnnotation?.type
      else {
        continue
      }

      bitFields.append(
        BitField(
          name: name,
          type: type,
          kind: kind,
          bits: arguments.bits,
          as: arguments.asType))
    }
    guard !error else { return [] }

    // MARK: Generate declaration

    var declarations = [DeclSyntax]()
    // Create a private init and a Never instance property to prevent users from
    // instancing the layout type directly.
    declarations.append("private init() { fatalError() }")
    declarations.append("private var _never: Never")

    // Create bit field types for each field contained in the layout type.
    declarations.append(
      contentsOf: bitFields.map {
        bitFieldType(
          acl: structDecl.accessLevel,
          bitWidth: bitWidth,
          bits: $0.bits,
          type: $0.type)
      })

    let isSymmetric = bitFields.allSatisfy(\.kind.isSymmetric)

    // Create a symmetric raw type ignoring read and write constraints as unsafe
    // escape hatch.
    declarations.append(
      contentsOf:
        rawType(
          acl: structDecl.accessLevel,
          layout: structDecl.name,
          bitWidth: bitWidth,
          bitFields: bitFields,
          isSymmetric: isSymmetric))

    if isSymmetric {
      // Create a single symmetric read-write type if all bit fields provide
      // symmetric views.
      declarations.append(
        contentsOf:
          readWriteType(
            acl: structDecl.accessLevel,
            layout: structDecl.name,
            bitWidth: bitWidth,
            bitFields: bitFields))
    } else {
      // Create two asymmetric read and write types if any of the bit fields
      // provide asymmetric views.
      declarations.append(
        contentsOf:
          readType(
            acl: structDecl.accessLevel,
            layout: structDecl.name,
            bitWidth: bitWidth,
            bitFields: bitFields))
      declarations.append(
        contentsOf:
          writeType(
            acl: structDecl.accessLevel,
            layout: structDecl.name,
            bitWidth: bitWidth,
            bitFields: bitFields))
    }

    return declarations
  }

  static func bitFieldType(
    acl: AccessLevel?,
    bitWidth: Int,
    bits: ExprSyntax,
    type: TypeSyntax
  ) -> DeclSyntax {
    """
    \(acl) enum \(type): BitField {
      \(acl) typealias RawStorage = UInt\(raw: bitWidth)
      \(acl) static let bitRange = \(bits)
    }
    """
  }

  static func rawType(
    acl: AccessLevel?,
    layout: TokenSyntax,
    bitWidth: Int,
    bitFields: [BitField],
    isSymmetric: Bool
  ) -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Create accessor declarations for each bitfield
    let bitFieldDeclarations: [DeclSyntax] = bitFields.map {
      """
      \(acl) var \($0.name): UInt\(raw: bitWidth) {
        @inline(__always) get { self._rawStorage[bits: \($0.type).bitRange] }
        @inline(__always) set { self._rawStorage[bits: \($0.type).bitRange] = newValue }
      }
      """
    }
    let initDeclarations: [DeclSyntax] =
      if isSymmetric {
        [
          "\(acl) init(_ value: Layout.ReadWrite) { self._rawStorage = value._rawStorage }"
        ]
      } else {
        [
          "\(acl) init(_ value: Layout.Read) { self._rawStorage = value._rawStorage }",
          "\(acl) init(_ value: Layout.Write) { self._rawStorage = value._rawStorage }",
        ]
      }

    // Produce Raw type declaration
    declarations.append(
      """
      \(acl) struct Raw: RegisterLayoutRaw {
        \(acl) typealias MMIOVolatileRepresentation = UInt\(raw: bitWidth)
        \(acl) typealias Layout = \(layout)
        \(acl) var _rawStorage: UInt\(raw: bitWidth)
        \(initDeclarations)
        \(bitFieldDeclarations)
      }
      """)
    return declarations
  }

  static func readWriteType(
    acl: AccessLevel?,
    layout: TokenSyntax,
    bitWidth: Int,
    bitFields: [BitField]
  ) -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Alias Read to ReadWrite
    declarations.append("\(acl) typealias Read = ReadWrite")
    // Alias Write to ReadWrite
    declarations.append("\(acl) typealias Write = ReadWrite")
    // Create accessor declarations for each readable bitfield
    let bitFieldDeclarations: [DeclSyntax] = bitFields
      .lazy
      .filter { $0.kind.isReadable && $0.kind.isWriteable }
      .map {
        """
        \(acl) var \($0.name): UInt\(raw: bitWidth) {
          @inline(__always) get { self._rawStorage[bits: \($0.type).bitRange] }
          @inline(__always) set { self._rawStorage[bits: \($0.type).bitRange] = newValue }
        }
        """
      }
    // Produce Read-Write type declaration
    declarations.append(
      """
      \(acl) struct ReadWrite: RegisterLayoutRead, RegisterLayoutWrite {
        \(acl) typealias MMIOVolatileRepresentation = UInt\(raw: bitWidth)
        \(acl) typealias Layout = \(layout)
        \(acl) var _rawStorage: UInt\(raw: bitWidth)
        \(acl) init(_ value: ReadWrite) { self._rawStorage = value._rawStorage }
        \(acl) init(_ value: Raw) { self._rawStorage = value._rawStorage }
        \(bitFieldDeclarations)
      }
      """)
    return declarations
  }

  static func readType(
    acl: AccessLevel?,
    layout: TokenSyntax,
    bitWidth: Int,
    bitFields: [BitField]
  ) -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Create accessor declarations for each readable bitfield
    let bitFieldDeclarations: [DeclSyntax] = bitFields
      .lazy
      .filter { $0.kind.isReadable }
      .map {
        """
        \(acl) var \($0.name): UInt\(raw: bitWidth) {
          @inline(__always) get { self._rawStorage[bits: \($0.type).bitRange] }
          @inline(__always) set { self._rawStorage[bits: \($0.type).bitRange] = newValue }
        }
        """
      }
    // Produce Read type declaration
    declarations.append(
      """
      \(acl) struct Read: RegisterLayoutRead {
        \(acl) typealias MMIOVolatileRepresentation = UInt\(raw: bitWidth)
        \(acl) typealias Layout = \(layout)
        \(acl) var _rawStorage: UInt\(raw: bitWidth)
        \(acl) init(_ value: Raw) { self._rawStorage = value._rawStorage }
        \(bitFieldDeclarations)
      }
      """)
    return declarations
  }

  static func writeType(
    acl: AccessLevel?,
    layout: TokenSyntax,
    bitWidth: Int,
    bitFields: [BitField]
  ) -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // TODO: better warning message
    // blocked-by: rdar://116130327 (Customizable deprecation messages)

    // Create accessor declarations for each readable bitfield
    let bitFieldDeclarations: [DeclSyntax] = bitFields
      .lazy
      .filter { $0.kind.isWriteable }
      .map {
        """
        \(acl) var \($0.name): UInt\(raw: bitWidth) {
          @available(*, deprecated, message: "API misuse; read from write view returns the value to be written, not the value initially read.")
          @inline(__always) get { self._rawStorage[bits: \($0.type).bitRange] }
          @inline(__always) set { self._rawStorage[bits: \($0.type).bitRange] = newValue }
        }
        """
      }
    // Produce Write type declaration
    declarations.append(
      """
      \(acl) struct Write: RegisterLayoutWrite {
        \(acl) typealias MMIOVolatileRepresentation = UInt\(raw: bitWidth)
        \(acl) typealias Layout = \(layout)
        \(acl) var _rawStorage: UInt\(raw: bitWidth)
        \(acl) init(_ value: Raw) { self._rawStorage = value._rawStorage }
        \(acl) init(_ value: Read) {
          // FIXME: mask off bits
          self._rawStorage = value._rawStorage
        }
        \(bitFieldDeclarations)
      }
      """)
    return declarations
  }
}

extension RegisterMacro: MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    // Avoid duplicating diagnostics produced by `MemberMacro` conformance.
    // Only apply unavailable annotations to var member decls of a struct decl
    // with exactly one bitField attribute.
    guard
      declaration.is(StructDeclSyntax.self),
      let varDecl = member.as(VariableDeclSyntax.self),
      varDecl.hasAttribute(oneOf: BitFieldKind.allCases) != nil
    else { return [] }
    return ["@available(*, unavailable)"]
  }
}

extension RegisterMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    let diagnostics = DiagnosticBuilder<Self>()

    let `extension`: DeclSyntax =
      """
      extension \(type.trimmed): RegisterLayout {}
      """

    guard let extensionDecl = `extension`.as(ExtensionDeclSyntax.self) else {
      context.diagnose(
        .init(
          node: `extension`,
          message: diagnostics.internalError()))
      return []
    }

    return [extensionDecl]
  }
}
