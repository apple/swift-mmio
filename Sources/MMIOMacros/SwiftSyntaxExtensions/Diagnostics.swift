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
import SwiftSyntaxMacroExpansion

struct ErrorDiagnostic {
  var diagnosticID: MessageID
  var severity = DiagnosticSeverity.error
  var message: String

  init(_ message: String, id: StaticString = #function) {
    self.diagnosticID = .init(domain: "MMIO", id: "\(id)")
    self.message = message
  }
}

extension ErrorDiagnostic: DiagnosticMessage {}

struct DiagnosticBuilder<Macro> where Macro: ParsableMacro {
  init(_: Macro.Type = Macro.self) {}
}

extension DiagnosticBuilder {
  static var internalErrorSuffix: String {
    """
    Please file an issue at \
    https://github.com/apple/swift-mmio/issues and, if possible, attach \
    the source code that triggered the issue
    """
  }

  func internalError() -> ErrorDiagnostic {
    .init("'\(Macro.signature)' internal error. \(Self.internalErrorSuffix)")
  }

  // Argument Parsing Errors
  func argumentMustIntegerLiteral(label: String) -> ErrorDiagnostic {
    .init(
      """
      '\(Macro.signature)' value for argument '\(label)' must be \
      an integer literal
      """)
  }

  func incorrectArgumentCount(
    expected: Int, actual: Int
  ) -> ErrorDiagnostic {
    .init(
      """
      '\(Macro.signature)' internal error. Incorrect number of arguments, \
      expected '\(expected)' received '\(actual)'. \(Self.internalErrorSuffix)
      """)
  }

  func incorrectArgumentLabel(
    index: Int, expected: String, actual: String
  ) -> ErrorDiagnostic {
    .init(
      """
      '\(Macro.signature)' internal error. Incorrect label for argument \
      \(index), expected '\(expected)' received '\(actual)'. \
      \(Self.internalErrorSuffix)
      """)
  }

  // Declaration Errors
  func onlyVarDecl() -> ErrorDiagnostic {
    .init("'\(Macro.signature)' can only be applied to properties")
  }

  func onlyDeclGroup(
    _ decl: DiagnosableDeclGroupSyntax.Type
  ) -> ErrorDiagnostic {
    .init("""
      '\(Macro.signature)' can only be applied to \(decl.declTypeName) \
      declarations
      """)
  }

  // Declaration Member Errors
  func onlyMemberVarDecls() -> ErrorDiagnostic {
    .init(
      """
      '\(Macro.signature)' struct can only contain properties
      """)
  }

  func onlyBankOffsetMemberVarDecls() -> ErrorDiagnostic {
    .init(
      """
      '\(Macro.signature)' struct properties must all be annotated with \
      '\(RegisterBankOffsetMacro.signature)'
      """)
  }

  func onlyBitFieldMemberVarDecls() -> ErrorDiagnostic {
    .init(
      """
      '\(Macro.signature)' struct property must be annotated \
      with a bitfield attribute
      """)
  }

  // Binding Errors
  func onlyVarBinding() -> ErrorDiagnostic {
    .init("'\(Macro.signature)' can only be applied to 'var' properties")
  }

  func onlySingleBinding() -> ErrorDiagnostic {
    .init("'\(Macro.signature)' cannot be applied to compound properties")
  }

  // Binding Identifier Errors
  func missingBindingIdentifier() -> ErrorDiagnostic {
    .init("'\(Macro.signature)' cannot be applied to anonymous properties")
  }

  func unexpectedTupleBindingIdentifier() -> ErrorDiagnostic {
    .init("'\(Macro.signature)' cannot be applied to tuple properties")
  }

  // Binding Type Errors
  func missingTypeAnnotation() -> ErrorDiagnostic {
    .init("'\(Macro.signature)' cannot be applied to untyped properties")
  }

  func unexpectedInferredType() -> ErrorDiagnostic {
    .init("""
      '\(Macro.signature)' cannot be applied to implicitly typed properties
      """)
  }

  // FIXME: I hate this diagnostic, what is a "simple type"
  func unexpectedBindingType() -> ErrorDiagnostic {
    .init("""
      '\(Macro.signature)' can only be applied to properties with simple types
      """)
  }

  func unexpectedAccessor() -> ErrorDiagnostic {
    .init("""
      '\(Macro.signature)' cannot be applied properties with custom accessors
      """)
  }
}

extension FixIt {
  static func replaceWithVar(node: TokenSyntax) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Replace '\(node.trimmed)' with 'var'"),
      oldNode: node,
      newNode: TokenSyntax.keyword(.var))
  }

  static func insertBindingType(node: PatternBindingSyntax) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Insert explicit type annotation"),
      oldNode: node,
      newNode: node.with(
        \.typeAnnotation,
        .init(
          EditorPlaceholderDeclSyntax(
            placeholder: .identifier("<#Type#>")))))
  }

  static func insertBindingIdentifier(node: PatternSyntax) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Insert explicit property identifier"),
      oldNode: node,
      newNode: EditorPlaceholderDeclSyntax(
        placeholder: .identifier("<#Identifier#>")))
  }

  static func removeAccessorBlock(node: PatternBindingSyntax) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Remove accessor block"),
      oldNode: node,
      newNode: node.with(\.accessorBlock, nil))
  }
}
