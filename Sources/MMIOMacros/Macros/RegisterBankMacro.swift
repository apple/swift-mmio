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

public enum RegisterBankMacro {}

extension RegisterBankMacro: Sendable {}

extension RegisterBankMacro: ParsableMacro {
  static let baseName = "RegisterBank"
  static let arguments = [(label: String, type: String)]()

  struct Arguments: ParsableMacroArguments {
    init(arguments: [ExprSyntax]) {}
  }
}

extension RegisterBankMacro: MMIOMemberMacro {
  static func mmioExpansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let context = MacroContext(Self.self, context)

    // Can only applied to structs.
    let structDecl = try declaration.requireAs(StructDeclSyntax.self, context)

    // Walk all the members of the struct.
    var error = false
    for member in structDecl.memberBlock.members {
      // Ignore non-variable declaration.
      guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
        continue
      }
      // Each variable declaration must be annotated with the
      // RegisterBankOffsetMacro. Further syntactic checking will be performed
      // by that macro.
      do {
        try variableDecl.requireMacro(RegisterBankOffsetMacro.self, context)
      } catch _ {
        error = true
      }
    }
    guard !error else { return [] }

    // Retrieve the access level of the struct, so we can use the same
    // access level for the unsafeAddress property and initializer.
    let acl = structDecl.accessLevel

    return [
      "\(acl)private(set) var unsafeAddress: UInt",
      """
      \(acl)init(unsafeAddress: UInt) {
        self.unsafeAddress = unsafeAddress
      }
      """,
    ]
  }
}
