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

public struct RegisterMacro {
  @Argument(label: "bitWidth")
  var bitWidth: BitWidth
}

extension RegisterMacro: Sendable {}

extension RegisterMacro: ParsableMacro {
  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    switch label {
    case "bitWidth":
      try self._bitWidth.update(from: expression, in: context)
    default:
      fatalError()
    }
  }

  init(arguments: Arguments) {
    self.bitWidth = arguments.bitWidth
  }
}

extension RegisterMacro: MMIOMemberMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool { false }

  func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] {
    // Can only applied to structs.
    let structDecl = try declaration.requireAs(StructDeclSyntax.self, context)

    // Walk all the members of the struct.
    var error = false
    var bitFields = [BitField]()
    for member in structDecl.memberBlock.members {
      // Each member must be a variable declaration.
      guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
        context.error(
          at: member.decl,
          message: .onlyMemberVarDecls())
        error = true
        continue
      }

      let suppressionContext = context.makeSuppressingDiagnostics()
      guard
        // Each declaration must be annotated with exactly one bitField macro.
        let value = try? variableDecl.requireMacro(bitFieldMacros, context),

        // Parse the arguments from the bitField macro.
        let macro = try? value.type.init(
          from: value.attribute,
          in: suppressionContext),

        // Grab the type of the variable declaration. Diagnostics will be
        // emitted by the handling of @attched(accessor) of the applied bitField
        // macro.
        let binding = variableDecl.singleBinding,
        let fieldName = binding.pattern.as(IdentifierPatternSyntax.self),
        let fieldType = binding.typeAnnotation?.type
      else {
        error = true
        continue
      }

      bitFields.append(
        BitField(
          type: value.type,
          fieldName: fieldName,
          fieldType: fieldType,
          bitRange: macro.bitRange,
          projectedType: macro.projectedType))
    }
    guard !error else { return [] }

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
          bitField: $0)
      })

    let isSymmetric = bitFields.allSatisfy { $0.type.isSymmetric }

    // Create a symmetric raw type ignoring read and write constraints as unsafe
    // escape hatch.
    declarations.append(
      contentsOf:
        rawType(
          acl: structDecl.accessLevel,
          layout: structDecl.name,
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
            bitFields: bitFields))
    } else {
      // Create two asymmetric read and write types if any of the bit fields
      // provide asymmetric views.
      declarations.append(
        contentsOf:
          readType(
            acl: structDecl.accessLevel,
            layout: structDecl.name,
            bitFields: bitFields))
      declarations.append(
        contentsOf:
          writeType(
            acl: structDecl.accessLevel,
            layout: structDecl.name,
            bitFields: bitFields))
    }

    return declarations
  }

  func bitFieldType(
    acl: AccessLevel?,
    bitField: BitField
  ) -> DeclSyntax {
    """
    \(acl)enum \(bitField.fieldType): BitField {
      \(acl)typealias RawStorage = UInt\(raw: self.bitWidth.value)
      \(acl)static let bitRange = \(raw: bitField.bitRange.description)
    }
    """
  }

  func rawType(
    acl: AccessLevel?,
    layout: TokenSyntax,
    bitFields: [BitField],
    isSymmetric: Bool
  ) -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Create accessor declarations for each bitfield
    let bitFieldDeclarations: [DeclSyntax] = bitFields.map {
      """
      \(acl)var \($0.fieldName): UInt\(raw: self.bitWidth.value) {
        @inline(__always) get { self._rawStorage[bits: \($0.fieldType).bitRange] }
        @inline(__always) set { self._rawStorage[bits: \($0.fieldType).bitRange] = newValue }
      }
      """
    }
    let initDeclarations: [DeclSyntax] =
      if isSymmetric {
        [
          "\(acl)init(_ value: Layout.ReadWrite) { self._rawStorage = value._rawStorage }"
        ]
      } else {
        [
          "\(acl)init(_ value: Layout.Read) { self._rawStorage = value._rawStorage }",
          "\(acl)init(_ value: Layout.Write) { self._rawStorage = value._rawStorage }",
        ]
      }

    // Produce Raw type declaration
    declarations.append(
      """
      \(acl)struct Raw: RegisterLayoutRaw {
        \(acl)typealias MMIOVolatileRepresentation = UInt\(raw: self.bitWidth.value)
        \(acl)typealias Layout = \(layout)
        \(acl)var _rawStorage: UInt\(raw: self.bitWidth.value)
        \(initDeclarations)
        \(bitFieldDeclarations)
      }
      """)
    return declarations
  }

  func readWriteType(
    acl: AccessLevel?,
    layout: TokenSyntax,
    bitFields: [BitField]
  ) -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Alias Read to ReadWrite
    declarations.append("\(acl)typealias Read = ReadWrite")
    // Alias Write to ReadWrite
    declarations.append("\(acl)typealias Write = ReadWrite")
    // Create accessor declarations for each readable bitfield
    let bitFieldDeclarations: [DeclSyntax] = bitFields
      .lazy
      .filter { $0.type.isReadable && $0.type.isWriteable }
      .map {
        """
        \(acl)var \($0.fieldName): UInt\(raw: self.bitWidth.value) {
          @inline(__always) get { self._rawStorage[bits: \($0.fieldType).bitRange] }
          @inline(__always) set { self._rawStorage[bits: \($0.fieldType).bitRange] = newValue }
        }
        """
      }
    // Produce Read-Write type declaration
    declarations.append(
      """
      \(acl)struct ReadWrite: RegisterLayoutRead, RegisterLayoutWrite {
        \(acl)typealias MMIOVolatileRepresentation = UInt\(raw: self.bitWidth.value)
        \(acl)typealias Layout = \(layout)
        \(acl)var _rawStorage: UInt\(raw: self.bitWidth.value)
        \(acl)init(_ value: ReadWrite) { self._rawStorage = value._rawStorage }
        \(acl)init(_ value: Raw) { self._rawStorage = value._rawStorage }
        \(bitFieldDeclarations)
      }
      """)
    return declarations
  }

  func readType(
    acl: AccessLevel?,
    layout: TokenSyntax,
    bitFields: [BitField]
  ) -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Create accessor declarations for each readable bitfield
    let bitFieldDeclarations: [DeclSyntax] = bitFields
      .lazy
      .filter { $0.type.isReadable }
      .map {
        """
        \(acl)var \($0.fieldName): UInt\(raw: self.bitWidth.value) {
          @inline(__always) get { self._rawStorage[bits: \($0.fieldType).bitRange] }
          @inline(__always) set { self._rawStorage[bits: \($0.fieldType).bitRange] = newValue }
        }
        """
      }
    // Produce Read type declaration
    declarations.append(
      """
      \(acl)struct Read: RegisterLayoutRead {
        \(acl)typealias MMIOVolatileRepresentation = UInt\(raw: self.bitWidth.value)
        \(acl)typealias Layout = \(layout)
        \(acl)var _rawStorage: UInt\(raw: self.bitWidth.value)
        \(acl)init(_ value: Raw) { self._rawStorage = value._rawStorage }
        \(bitFieldDeclarations)
      }
      """)
    return declarations
  }

  func writeType(
    acl: AccessLevel?,
    layout: TokenSyntax,
    bitFields: [BitField]
  ) -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // FIXME: improve warning message
    // blocked-by: rdar://116130327 (Customizable deprecation messages)

    // Create accessor declarations for each readable bitfield
    let bitFieldDeclarations: [DeclSyntax] = bitFields
      .lazy
      .filter { $0.type.isWriteable }
      .map {
        """
        \(acl)var \($0.fieldName): UInt\(raw: self.bitWidth.value) {
          @available(*, deprecated, message: "API misuse; read from write view returns the value to be written, not the value initially read.")
          @inline(__always) get { self._rawStorage[bits: \($0.fieldType).bitRange] }
          @inline(__always) set { self._rawStorage[bits: \($0.fieldType).bitRange] = newValue }
        }
        """
      }
    // Produce Write type declaration
    declarations.append(
      """
      \(acl)struct Write: RegisterLayoutWrite {
        \(acl)typealias MMIOVolatileRepresentation = UInt\(raw: self.bitWidth.value)
        \(acl)typealias Layout = \(layout)
        \(acl)var _rawStorage: UInt\(raw: self.bitWidth.value)
        \(acl)init(_ value: Raw) { self._rawStorage = value._rawStorage }
        \(acl)init(_ value: Read) {
          // FIXME: mask off bits
          self._rawStorage = value._rawStorage
        }
        \(bitFieldDeclarations)
      }
      """)
    return declarations
  }
}

extension RegisterMacro: MMIOMemberAttributeMacro {
  static var memberAttributeMacroSuppressParsingDiagnostics: Bool { true }

  func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [AttributeSyntax] {
    // Avoid duplicating diagnostics produced by `MemberMacro` conformance.
    let context = MacroContext.makeSuppressingDiagnostics(Self.self)
    // Only apply unavailable annotations to var member decls of a struct decl
    // with exactly one bitField attribute.
    guard
      declaration.is(StructDeclSyntax.self),
      let variableDecl = member.as(VariableDeclSyntax.self),
      (try? variableDecl.requireMacro(bitFieldMacros, context)) != nil
    else { return [] }
    return ["@available(*, unavailable)"]
  }
}

extension RegisterMacro: MMIOExtensionMacro {
  static var extensionMacroSuppressParsingDiagnostics: Bool { true }

  func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [ExtensionDeclSyntax] {
    // Avoid duplicating diagnostics produced by `MemberMacro` conformance.
    // Only create extension when applied to struct decls.
    guard declaration.is(StructDeclSyntax.self) else { return [] }

    let `extension`: DeclSyntax = "extension \(type.trimmed): RegisterLayout {}"

    guard let extensionDecl = `extension`.as(ExtensionDeclSyntax.self) else {
      context.error(
        at: `extension`,
        message: .internalError())
      return []
    }

    return [extensionDecl]
  }
}
