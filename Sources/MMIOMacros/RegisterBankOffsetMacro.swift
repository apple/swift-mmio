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

public enum RegisterBankOffsetMacro {
  static let baseName = "RegisterBank"
}

extension RegisterBankOffsetMacro {
  struct Arguments {
    var offset: ExprSyntax

    init?(node: AttributeSyntax, context: some MacroExpansionContext) {
      let arguments = MacroArgumentParser.parse(
        macro: "@RegisterBank(offset:)",
        labels: ["offset"],
        node: node,
        context: context)
      guard let arguments = arguments else { return nil }
      self.offset = arguments[0]
    }
  }
}

extension RegisterBankOffsetMacro: AccessorMacro {
  /// Expand a macro that's expressed as a custom attribute attached to
  /// the given declaration. The result is a set of accessors for the
  /// declaration.
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard let arguments = Arguments(node: node, context: context) else {
      return []
    }

    // Can only applied to variables.
    guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
      context.diagnose(
        .init(
          node: declaration,
          message: Diagnostics.Errors.onlyVarDecl()))
      return []
    }

    // Must be `var` binding.
    guard variableDecl.bindingKind == .var else {
      context.diagnose(
        .init(
          node: variableDecl.bindingSpecifier,
          message: Diagnostics.Errors.onlyVarBinding(),
          fixIt: Diagnostics.FixIts.replaceWithVar(
            node: variableDecl.bindingSpecifier)))
      return []
    }

    // Exactly one binding for the variable.
    guard let binding = variableDecl.binding else {
      context.diagnose(
        .init(
          node: variableDecl.bindings,
          message: Diagnostics.Errors.onlySingleBinding()))
      return []
    }

    // Binding identifier must be a simple identifier
    guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
      if binding.pattern.is(TuplePatternSyntax.self) {
        // Binding identifier must not be a tuple.
        context.diagnose(
          .init(
            node: binding.pattern,
            message: Diagnostics.Errors.unexpectedTupleBindingIdentifier()))
        return []
      } else if binding.pattern.is(WildcardPatternSyntax.self) {
        context.diagnose(
          .init(
            node: binding.pattern,
            message: Diagnostics.Errors.missingBindingIdentifier(),
            fixIt: Diagnostics.FixIts.insertBindingIdentifier(
              node: binding.pattern)))
        return []
      } else {
        context.diagnose(
          .init(
            node: binding.pattern,
            message: Diagnostics.Errors.internal()))
        return []
      }
    }

    // Binding identifier must not be "_" (implicitly named).
    guard identifierPattern.identifier.tokenKind != .wildcard else {
      context.diagnose(
        .init(
          node: binding.pattern,
          message: Diagnostics.Errors.missingBindingIdentifier(),
          fixIt: Diagnostics.FixIts.insertBindingIdentifier(
            node: binding.pattern)))
      return []
    }

    // Binding must have a type annotation.
    guard let type = binding.typeAnnotation?.type else {
      context.diagnose(
        .init(
          node: binding,
          message: Diagnostics.Errors.missingTypeAnnotation(),
          fixIt: Diagnostics.FixIts.insertBindingType(
            node: binding)))
      return []
    }

    // Binding type must be a simple identifier; not an optional, tuple,
    // array, etc...
    if let typeIdentifier = type.as(IdentifierTypeSyntax.self) {
      // Binding type must not be "_" (implicitly typed).
      guard typeIdentifier.name.tokenKind != .wildcard else {
        context.diagnose(
          .init(
            node: type,
            message: Diagnostics.Errors.unexpectedInferredType(),
            fixIt: Diagnostics.FixIts.insertBindingType(
              node: binding)))
        return []
      }
    } else if type.is(MemberTypeSyntax.self) {
      // Ok
    } else {
      context.diagnose(
        .init(
          node: type,
          message: Diagnostics.Errors.unexpectedBindingType()))
      return []
    }

    // Binding must not have any accessors.
    if let accessorBlock = binding.accessorBlock {
      context.diagnose(
        .init(
          node: accessorBlock,
          message: Diagnostics.Errors.unexpectedAccessor(),
          fixIt: Diagnostics.FixIts.removeAccessorBlock(
            node: binding)))
      return []
    }

    return [
      """
      @inline(__always) get { .init(unsafeAddress: self.unsafeAddress + (\(arguments.offset))) }
      """
    ]
  }
}

extension RegisterBankOffsetMacro {
  enum Diagnostics {
    struct Errors: DiagnosticMessage {
      var id: StaticString
      var diagnosticID: MessageID {
        .init(domain: "\(RegisterBankOffsetMacro.self)", id: "\(self.id)")
      }
      var severity: DiagnosticSeverity
      var message: String

      init(
        message: String,
        severity: DiagnosticSeverity = .error,
        id: StaticString = #function
      ) {
        self.id = id
        self.severity = severity
        self.message = message
      }

      // Internal Errors
      static func `internal`() -> Self {
        self.init(
          message: """
            '@RegisterBank(offset:)' internal error. Please file an issue at \
            https://github.com/apple/swift-mmio/issues and, if possible, \
            attach the source code that triggered the issue
            """)
      }

      // General Declaration/Binding Errors
      static func onlyVarDecl() -> Self {
        self.init(message: "'@RegisterBank(offset:)' can only be applied to properties")
      }

      static func onlyVarBinding() -> Self {
        self.init(message: "'@RegisterBank(offset:)' can only be applied to 'var' properties")
      }

      static func onlySingleBinding() -> Self {
        self.init(message: "'@RegisterBank(offset:)' cannot be applied to compound properties")
      }

      // Binding Identifier Errors
      static func missingBindingIdentifier() -> Self {
        self.init(message: "'@RegisterBank(offset:)' cannot be applied to anonymous properties")
      }

      static func unexpectedTupleBindingIdentifier() -> Self {
        self.init(message: "'@RegisterBank(offset:)' cannot be applied to tuple properties")
      }

      // Binding Type Errors
      static func missingTypeAnnotation() -> Self {
        self.init(message: "'@RegisterBank(offset:)' cannot be applied to untyped properties")
      }

      static func unexpectedInferredType() -> Self {
        self.init(message: "'@RegisterBank(offset:)' cannot be applied to implicitly typed properties")
      }

      // FIXME: I hate this diagnostic, what is a "simple type"
      static func unexpectedBindingType() -> Self {
        self.init(message: "'@RegisterBank(offset:)' can only be applied to properties with simple types")
      }

      static func unexpectedAccessor() -> Self {
        self.init(message: "'@RegisterBank(offset:)' cannot be applied properties with custom accessors")
      }
    }

    enum FixIts {
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
  }
}
