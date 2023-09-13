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

    init(node: AttributeSyntax, context: some MacroExpansionContext) {
      guard
        let arguments = node.arguments,
        let arguments = arguments.as(LabeledExprListSyntax.self),
        arguments.count == 1
      else { fatalError() }

      self.offset = ExprSyntax(literal: "")
      var uninitializedProperties = Set<String>([
        "offset"
      ])

      for argument in arguments {
        guard
          let label = argument.label?.text,
          uninitializedProperties.remove(label) != nil
        else { fatalError() }
        switch label {
        case "offset":
          self.offset = argument.expression
        default:
          fatalError()
        }
      }
      guard uninitializedProperties.isEmpty else { fatalError() }
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
    let arguments = Arguments(node: node, context: context)

    // Can only applied to variables.
    guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
      context.diagnose(
        .init(
          node: declaration,
          message: Diagnostics.Errors.OnlyVarDecl()))
      return []
    }

    // Must be `var` binding.
    guard variableDecl.bindingKind == .var else {
      context.diagnose(
        .init(
          node: variableDecl.bindingSpecifier,
          message: Diagnostics.Errors.OnlyVarBinding(),
          fixIt: Diagnostics.FixIts.replaceWithVar(
            node: variableDecl.bindingSpecifier)))
      return []
    }

    // Exactly one binding for the variable.
    guard let binding = variableDecl.binding else {
      context.diagnose(
        .init(
          node: variableDecl.bindings,
          message: Diagnostics.Errors.OnlySingleBinding()))
      return []
    }

    // Binding identifier must be a simple identifier
    guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
      if binding.pattern.is(TuplePatternSyntax.self) {
        // Binding identifier must not be a tuple.
        context.diagnose(
          .init(
            node: binding.pattern,
            message: Diagnostics.Errors.UnexpectedTupleBindingIdentifier()))
        return []
      } else if binding.pattern.is(WildcardPatternSyntax.self) {
        context.diagnose(
          .init(
            node: binding.pattern,
            message: Diagnostics.Errors.MissingBindingIdentifier(),
            fixIt: Diagnostics.FixIts.insertBindingIdentifier(
              node: binding.pattern)))
        return []
      } else {
        context.diagnose(
          .init(
            node: binding.pattern,
            message: Diagnostics.Errors.Internal()))
        return []
      }
    }

    // Binding identifier must not be "_" (implicitly named).
    guard identifierPattern.identifier.tokenKind != .wildcard else {
      context.diagnose(
        .init(
          node: binding.pattern,
          message: Diagnostics.Errors.MissingBindingIdentifier(),
          fixIt: Diagnostics.FixIts.insertBindingIdentifier(
            node: binding.pattern)))
      return []
    }

    // Binding must have a type annotation.
    guard let type = binding.typeAnnotation?.type else {
      context.diagnose(
        .init(
          node: binding,
          message: Diagnostics.Errors.MissingTypeAnnotation(),
          fixIt: Diagnostics.FixIts.insertBindingType(
            node: binding)))
      return []
    }

    // Binding type must be a simple identifier (not an optional, tuple,
    // array, etc...
    guard let typeIdentifier = type.as(IdentifierTypeSyntax.self) else {
      // Type annotation must not be a tuple.
      context.diagnose(
        .init(
          node: type,
          message: Diagnostics.Errors.UnexpectedBindingType()))
      return []
    }

    // Binding type must not be "_" (implicitly typed).
    guard typeIdentifier.name.tokenKind != .wildcard else {
      context.diagnose(
        .init(
          node: type,
          message: Diagnostics.Errors.UnexpectedInferredType(),
          fixIt: Diagnostics.FixIts.insertBindingType(
            node: binding)))
      return []
    }

    // Binding must not have any accessors.
    if let accessorBlock = binding.accessorBlock {
      context.diagnose(
        .init(
          node: accessorBlock,
          message: Diagnostics.Errors.UnexpectedAccessor(),
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
    enum Errors {
      struct Internal: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' internal error. Please file an issue at https://github.com/apple/swift-mmio/issues"
        var severity = DiagnosticSeverity.error
      }

      struct OnlyVarDecl: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' can only be applied to properties"
        var severity = DiagnosticSeverity.error
      }

      struct OnlyVarBinding: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' can only be applied to 'var' properties"
        var severity = DiagnosticSeverity.error
      }

      struct OnlySingleBinding: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' cannot be applied to compound properties"
        var severity = DiagnosticSeverity.error
      }

      // Binding Identifier Errors
      struct MissingBindingIdentifier: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' cannot be applied to anonymous properties"
        var severity = DiagnosticSeverity.error
      }

      struct UnexpectedTupleBindingIdentifier: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' cannot be applied to tuple properties"
        var severity = DiagnosticSeverity.error
      }

      // Binding Type Errors
      struct MissingTypeAnnotation: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' cannot be applied to untyped properties"
        var severity = DiagnosticSeverity.error
      }

      struct UnexpectedInferredType: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' cannot be applied to implicitly typed properties"
        var severity = DiagnosticSeverity.error
      }

      struct UnexpectedBindingType: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        // FIXME: I hate this diagnostic, what is a "simple type"
        var message =
          "'@RegisterBank(offset:)' can only be applied to properties with simple types"
        var severity = DiagnosticSeverity.error
      }

      struct UnexpectedAccessor: DiagnosticMessage {
        var diagnosticID = MessageID(
          domain: "\(RegisterBankOffsetMacro.self)",
          id: "\(Self.self)")
        var message =
          "'@RegisterBank(offset:)' cannot be applied properties with custom accessors"
        var severity = DiagnosticSeverity.error
      }
    }

    enum FixIts {
      static func replaceWithVar(node: TokenSyntax) -> FixIt {
        .replace(
          message: MacroExpansionFixItMessage(
            "Replace '\(node.trimmed)' with 'var'"),
          oldNode: node,
          // FIXME: Should this be EditorPlaceholderDeclSyntax?
          newNode: EditorPlaceholderDeclSyntax(
            placeholder: .keyword(.var)))
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
