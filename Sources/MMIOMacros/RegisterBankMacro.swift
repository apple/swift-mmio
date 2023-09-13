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

public enum RegisterBankMacro {
  static let baseName = "RegisterBank"
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
    // Can only applied to structs.
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      guard let introducer = declaration as? HasIntroducerKeyword else {
        context.diagnose(
          .init(
            node: declaration,
            message: Diagnostics.Errors.OnlyStructDecl()))
        return []
      }
      context.diagnose(
        .init(
          node: introducer.introducerKeyword,
          message: Diagnostics.Errors.OnlyStructDecl()))
      return []
    }

    // Walk all the members of the struct. Each variable declaration must be
    // annotated with the RegisterBank(offset:) macro. Further syntactic
    // checking will be performed by that macro.
    var error = false
    for member in structDecl.memberBlock.members {
      // Ignore non-variable declaration.
      guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
        continue
      }
      // Each variable declaration must be annotated with the
      // RegisterBank(offset:) macro.
      var isAnnotated = false
      for attribute in variableDecl.attributes {
        guard case .attribute(let attributeSyntax) = attribute else {
          continue
        }
        guard let identifier = attributeSyntax.attributeName.as(IdentifierTypeSyntax.self) else {
          continue
        }
        // Further syntactic checking will be performed by
        // RegisterBankOffsetMacro.
        if identifier.name.text == RegisterBankOffsetMacro.baseName {
          isAnnotated = true
          break
        }
      }
      guard isAnnotated else {
        // FIXME: Add fixit
        // fixit: insert @RegisterBank(offset: <#Int#>)
        context.diagnose(
          .init(
            node: variableDecl,
            message: Diagnostics.Errors.OnlyAnnotatedMemberVarDecls()))
        error = true
        continue
      }
    }
    guard !error else { return [] }

    // Retrieve the access level of the struct, so we can use the same
    // access level for the unsafeAddress property and initializer.
    let declAccessLevel = structDecl.accessLevel

    return [
      """
      \(declAccessLevel) var unsafeAddress: UInt
      """,
      """
      \(declAccessLevel) init(unsafeAddress: UInt) { self.unsafeAddress = unsafeAddress }
      """,
    ]
  }
}

extension RegisterBankMacro {
  enum Diagnostics {
    enum Errors {
      struct OnlyStructDecl: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank' can only be applied to structs"
        var severity = DiagnosticSeverity.error
      }

      struct OnlyAnnotatedMemberVarDecls: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank' struct properties must all be annotated with '@RegisterBank(offset:)'"
        var severity = DiagnosticSeverity.error
      }
    }

    enum FixIts {

    }
  }
}
