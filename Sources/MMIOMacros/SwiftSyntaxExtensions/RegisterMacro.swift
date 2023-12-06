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
}

extension RegisterMacro: MMIOMemberMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool { false }

  func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] {
    // Can only applied to structs.
    // FIXME: https://github.com/apple/swift-syntax/pull/2366
    // swift-format-ignore: NeverForceUnwrap
    let declaration = declaration as! DeclSyntaxProtocol
    let structDecl = try declaration.requireAs(StructDeclSyntax.self, context)
    let accessLevel = structDecl.accessLevel
    let bitWidth = self.bitWidth.value

    // Walk all the members of the struct.
    var error = false
    var isSymmetric = true
    var bitFields = [BitFieldDescription]()
    for member in structDecl.memberBlock.members {
      // Each member must be a variable declaration.
      guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
        _ = context.error(
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

      isSymmetric = isSymmetric && value.type.isSymmetric

      bitFields.append(
        BitFieldDescription(
          accessLevel: accessLevel,
          bitWidth: bitWidth,
          type: value.type,
          fieldName: fieldName,
          fieldType: fieldType,
          bitRanges: macro.bitRanges,
          projectedType: macro.projectedType?.expression))
    }
    guard !error else { return [] }

    let register = RegisterDescription(
      name: structDecl.name,
      accessLevel: structDecl.accessLevel,
      bitWidth: self.bitWidth.value,
      bitFields: bitFields,
      isSymmetric: isSymmetric)

    try register.validate()
    return register.declarations()
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

    let `extension`: DeclSyntax = "extension \(type.trimmed): RegisterValue {}"

    return [try `extension`.requireAs(ExtensionDeclSyntax.self, context)]
  }
}
