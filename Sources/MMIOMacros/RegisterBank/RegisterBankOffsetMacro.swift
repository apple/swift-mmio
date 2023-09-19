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

public enum RegisterBankOffsetMacro {}

extension RegisterBankOffsetMacro: ParsableMacro {
  static let baseName = "RegisterBank"
  static let labels = ["offset"]

  struct Arguments: ParsableMacroArguments {
    var offset: ExprSyntax

    init(arguments: [ExprSyntax]) {
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
    let diagnostics = DiagnosticBuilder<Self>()

    guard let arguments = Self.parse(from: node, in: context) else {
      return []
    }

    // Can only applied to variables.
    guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
      context.diagnose(
        .init(
          node: declaration,
          message: diagnostics.onlyVarDecl()))
      return []
    }

    // Must be `var` binding.
    guard variableDecl.bindingKind == .var else {
      context.diagnose(
        .init(
          node: variableDecl.bindingSpecifier,
          message: diagnostics.onlyVarBinding(),
          fixIt: .replaceWithVar(node: variableDecl.bindingSpecifier)))
      return []
    }

    // Exactly one binding for the variable.
    guard let binding = variableDecl.binding else {
      context.diagnose(
        .init(
          node: variableDecl.bindings,
          message: diagnostics.onlySingleBinding()))
      return []
    }

    // Binding identifier must be a simple identifier
    guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
      if binding.pattern.is(TuplePatternSyntax.self) {
        // Binding identifier must not be a tuple.
        context.diagnose(
          .init(
            node: binding.pattern,
            message: diagnostics.unexpectedTupleBindingIdentifier()))
        return []
      } else if binding.pattern.is(WildcardPatternSyntax.self) {
        context.diagnose(
          .init(
            node: binding.pattern,
            message: diagnostics.missingBindingIdentifier(),
            fixIt: .insertBindingIdentifier(node: binding.pattern)))
        return []
      } else {
        context.diagnose(
          .init(
            node: binding.pattern,
            message: diagnostics.internalError()))
        return []
      }
    }

    // Binding identifier must not be "_" (implicitly named).
    guard identifierPattern.identifier.tokenKind != .wildcard else {
      context.diagnose(
        .init(
          node: binding.pattern,
          message: diagnostics.missingBindingIdentifier(),
          fixIt: .insertBindingIdentifier(node: binding.pattern)))
      return []
    }

    // Binding must have a type annotation.
    guard let type = binding.typeAnnotation?.type else {
      context.diagnose(
        .init(
          node: binding,
          message: diagnostics.missingTypeAnnotation(),
          fixIt: .insertBindingType(node: binding)))
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
            message: diagnostics.unexpectedInferredType(),
            fixIt: .insertBindingType(node: binding)))
        return []
      }
    } else if type.is(MemberTypeSyntax.self) {
      // Ok
    } else {
      context.diagnose(
        .init(
          node: type,
          message: diagnostics.unexpectedBindingType()))
      return []
    }

    // Binding must not have any accessors.
    if let accessorBlock = binding.accessorBlock {
      context.diagnose(
        .init(
          node: accessorBlock,
          message: diagnostics.unexpectedAccessor(),
          fixIt: .removeAccessorBlock(node: binding)))
      return []
    }

    return [
      """
      @inline(__always) get { .init(unsafeAddress: self.unsafeAddress + (\(arguments.offset))) }
      """
    ]
  }
}
