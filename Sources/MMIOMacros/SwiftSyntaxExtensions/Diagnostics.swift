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
import SwiftSyntaxMacros

struct ExpansionError: Error {}

struct ErrorDiagnostic<Macro> where Macro: ParsableMacro {
  var diagnosticID: MessageID
  var severity = DiagnosticSeverity.error
  var message: String

  init(_ message: String, id: StaticString = #function) {
    self.diagnosticID = .init(domain: "MMIO", id: "\(id)")
    self.message = message
  }
}

extension ErrorDiagnostic: DiagnosticMessage {}

extension ErrorDiagnostic {
  static var internalErrorSuffix: String {
    """
    Please file an issue at \
    https://github.com/apple/swift-mmio/issues and, if possible, attach \
    the source code that triggered the issue
    """
  }

  static func internalError() -> Self {
    .init("'\(Macro.signature)' internal error. \(Self.internalErrorSuffix)")
  }

  // Argument Parsing Errors
  static func argumentMustIntegerLiteral(label: String) -> Self {
    .init(
      """
      '\(Macro.signature)' value for argument '\(label)' must be \
      an integer literal
      """)
  }

  static func argumentValueMustBeOneOf(label: String, values: [Int]) -> Self {
    precondition(values.count > 1)
    guard let last = values.last else { fatalError() }

    let options =
      values
      .dropLast()
      .map { "'\($0)'" }
      .joined(separator: ", ")
      .appending(", or ")
      .appending("'\(last)'")

    return .init(
      """
      '\(Macro.signature)' value for argument '\(label)' must be one of
      \(options)
      """)
  }

  static func incorrectArgumentCount(
    expected: Int, actual: Int
  ) -> Self {
    .init(
      """
      '\(Macro.signature)' internal error. Incorrect number of arguments, \
      expected '\(expected)' received '\(actual)'. \(Self.internalErrorSuffix)
      """)
  }

  static func incorrectArgumentLabel(
    index: Int, expected: String, actual: String
  ) -> Self {
    .init(
      """
      '\(Macro.signature)' internal error. Incorrect label for argument \
      \(index), expected '\(expected)' received '\(actual)'. \
      \(Self.internalErrorSuffix)
      """)
  }

  // Declaration Errors
  static func expectedVarDecl() -> Self {
    .init("'\(Macro.signature)' can only be applied to properties")
  }

  static func expectedDecl(_ decl: DiagnosableDeclGroupSyntax.Type) -> Self {
    .init(
      """
      '\(Macro.signature)' can only be applied to \(decl.declTypeName) \
      declarations
      """)
  }

  // Declaration Member Errors
  static func onlyMemberVarDecls() -> Self {
    .init(
      """
      '\(Macro.signature)' type can only contain properties
      """)
  }

  static func expectedMemberAnnotatedWithMacro<OtherMacro>(
    _ macro: OtherMacro.Type
  ) -> Self where OtherMacro: ParsableMacro {
    .init(
      """
      '\(Macro.signature)' type member must be annotated with \
      '\(OtherMacro.signature)' macro
      """)
  }

  static func expectedMemberAnnotatedWithOneOf(
    _ macros: [any ParsableMacro.Type]
  ) -> Self {
    precondition(macros.count > 1)
    guard let last = macros.last else { fatalError() }

    let options =
      macros
      .dropLast()
      .map { "'\($0.signature)'" }
      .joined(separator: ", ")
      .appending(", or ")
      .appending("'\(last.signature)'")

    return .init(
      """
      '\(Macro.signature)' type member must be annotated with exactly one \
      macro of \(options)
      """)
  }

  // Binding Errors
  static func expectedBindingKind(_ bindingKind: VariableBindingKind) -> Self {
    .init(
      """
      '\(Macro.signature)' can only be applied to '\(bindingKind)' properties
      """)
  }

  static func expectedSingleBinding() -> Self {
    .init("'\(Macro.signature)' cannot be applied to compound properties")
  }

  // Binding Identifier Errors
  static func expectedBindingIdentifier() -> Self {
    .init("'\(Macro.signature)' cannot be applied to anonymous properties")
  }

  static func unexpectedTupleBindingIdentifier() -> Self {
    .init("'\(Macro.signature)' cannot be applied to tuple properties")
  }

  // Binding Type Errors
  static func expectedTypeAnnotation() -> Self {
    .init("'\(Macro.signature)' cannot be applied to untyped properties")
  }

  static func unexpectedInferredType() -> Self {
    .init(
      """
      '\(Macro.signature)' cannot be applied to implicitly typed properties
      """)
  }

  // FIXME: Improve diagnostic, what is a "simple type"?
  static func unexpectedBindingType() -> Self {
    .init(
      """
      '\(Macro.signature)' can only be applied to properties with simple types
      """)
  }

  static func expectedStoredProperty() -> Self {
    .init(
      """
      '\(Macro.signature)' cannot be applied properties with accessors
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
    // FIXME: https://github.com/apple/swift-syntax/issues/2205
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

  static func insertMacro<Macro>(
    node: some WithAttributesSyntax, _: Macro.Type
  ) -> FixIt where Macro: ParsableMacro {
    // FIXME: https://github.com/apple/swift-syntax/issues/2205
    var newNode = node
    newNode.attributes.append(Macro.placeholder)
    return .replace(
      message: MacroExpansionFixItMessage("Insert '\(Macro.signature)' macro"),
      oldNode: node,
      newNode: newNode)
  }

  static func removeAccessorBlock(node: PatternBindingSyntax) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Remove accessor block"),
      oldNode: node,
      newNode: node.with(\.accessorBlock, nil))
  }
}

struct MacroContext<Macro, Context>
where Macro: ParsableMacro, Context: MacroExpansionContext {
  var context: Context

  init(_: Macro.Type = Macro.self, _ context: Context) {
    self.context = context
  }

  func error(
    at node: some SyntaxProtocol,
    message: ErrorDiagnostic<Macro>,
    highlights: [Syntax]? = nil,
    notes: [Note] = [],
    fixIts: FixIt...
  ) {
    self.context.diagnose(
      .init(
        node: node,
        position: nil,
        message: message,
        highlights: highlights,
        notes: notes,
        fixIts: fixIts))
  }
}

extension MacroContext where Context == SuppressionContext {
  static func makeSuppressingDiagnostics(
    _: Macro.Type = Macro.self
  ) -> MacroContext<Macro, SuppressionContext> {
    self.init(Macro.self, .init())
  }
}

class SuppressionContext: MacroExpansionContext {
  func location(
    of node: some SyntaxProtocol,
    at position: PositionInSyntaxNode,
    filePathMode: SourceLocationFilePathMode
  ) -> SwiftSyntaxMacros.AbstractSourceLocation? {
    nil
  }

  func makeUniqueName(_ name: String) -> TokenSyntax {
    fatalError("Unsupported")
  }

  func diagnose(_ diagnostic: SwiftDiagnostics.Diagnostic) {
    // ignore
  }
}
