//===----------------------------------------------------------------------===//
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
import SwiftSyntaxMacros

public struct RegisterBlockMacro {}

extension RegisterBlockMacro: ParsableMacro {
  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    fatalError()
  }
}

extension RegisterBlockMacro: MMIOMemberMacro {
  static let memberMacroSuppressParsingDiagnostics: Bool = false

  func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] {
    // Can only applied to structs.
    let structDecl = try declaration.requireAs(StructDeclSyntax.self, context)

    // Walk all the members of the struct.
    var error = false
    for member in structDecl.memberBlock.members {
      guard
        // Ignore non-variable declarations.
        let variableDecl = member.decl.as(VariableDeclSyntax.self),
        // Ignore non-stored properties.
        !variableDecl.isComputedProperty
      else {
        continue
      }

      // Each variable declaration must be annotated with the
      // RegisterBlockOffsetMacro. Further syntactic checking will be performed
      // by that macro.
      do {
        try variableDecl.requireMacro(registerBlockMemberMacros, context)
      } catch _ {
        error = true
      }
    }

    guard !error else { return [] }

    // Retrieve the access level of the struct, so we can use the same
    // access level for the unsafeAddress property and initializer.
    var accessLevel = structDecl.accessLevel?.trimmed
    accessLevel?.trailingTrivia = .spaces(1)

    return [
      "\(accessLevel)let unsafeAddress: UInt",
      """
      #if FEATURE_INTERPOSABLE
      \(accessLevel)var interposer: (any MMIOInterposer)?
      #endif
      """,
      """
      #if FEATURE_INTERPOSABLE
      @inlinable @inline(__always)
      \(accessLevel)init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?) {
        self.unsafeAddress = unsafeAddress
        self.interposer = interposer
      }
      #else
      @inlinable @inline(__always)
      \(accessLevel)init(unsafeAddress: UInt) {
        self.unsafeAddress = unsafeAddress
      }
      #endif
      """,
    ]
  }
}

extension RegisterBlockMacro: MMIOExtensionMacro {
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

    let `extension`: DeclSyntax =
      "extension \(type.trimmed): RegisterProtocol {}"

    return [try `extension`.requireAs(ExtensionDeclSyntax.self, context)]
  }
}
