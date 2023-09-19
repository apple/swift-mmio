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

extension RegisterBankMacro: ParsableMacro {
  static let baseName = "RegisterBank"
  static let labels = [String]()

  struct Arguments: ParsableMacroArguments {
    init(arguments: [ExprSyntax]) {}
  }
}

extension RegisterBankMacro: MemberMacro {
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

    // Can only applied to structs.
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      guard let introducer = declaration as? HasIntroducerKeyword else {
        context.diagnose(
          .init(
            node: declaration,
            message: diagnostics.onlyStructDecl()))
        return []
      }
      context.diagnose(
        .init(
          node: introducer.introducerKeyword,
          message: diagnostics.onlyStructDecl()))
      return []
    }

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
      guard variableDecl.hasAttribute(RegisterBankOffsetMacro.baseName) else {
        // FIXME: Add fixit
        // fixit: insert @RegisterBank(offset: <#Int#>)
        context.diagnose(
          .init(
            node: variableDecl,
            message: diagnostics.onlyBankOffsetMemberVarDecls()))
        error = true
        continue
      }
    }
    guard !error else { return [] }

    // Retrieve the access level of the struct, so we can use the same
    // access level for the unsafeAddress property and initializer.
    let declAccessLevel = structDecl.accessLevel

    return [
      "\(declAccessLevel) var unsafeAddress: UInt",
      "\(declAccessLevel) init(unsafeAddress: UInt) { self.unsafeAddress = unsafeAddress }",
    ]
  }
}
