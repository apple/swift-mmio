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

public struct RegisterBankOffsetMacro {
  @Argument(label: "offset")
  var offset: Int
}

extension RegisterBankOffsetMacro: Sendable {}

extension RegisterBankOffsetMacro: ParsableMacro {
  static let baseName = "RegisterBank"

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    switch label {
    case "offset":
      try self._offset.update(from: expression, in: context)
    default:
      fatalError()
    }
  }
}

extension RegisterBankOffsetMacro: MMIOAccessorMacro {
  static var accessorMacroSuppressParsingDiagnostics: Bool { false }

  func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [AccessorDeclSyntax] {
    // Can only applied to variables.
    let variableDecl =
      try declaration.requireAs(VariableDeclSyntax.self, context)

    // Must be `var` binding.
    try variableDecl.requireBindingSpecifier(.var, context)

    // Exactly one binding for the variable.
    let binding = try variableDecl.requireSingleBinding(context)

    // Binding identifier must be a simple identifier
    guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
      if binding.pattern.is(TuplePatternSyntax.self) {
        // Binding identifier must not be a tuple.
        throw context.error(
          at: binding.pattern,
          message: .unexpectedTupleBindingIdentifier())
      } else if binding.pattern.is(WildcardPatternSyntax.self) {
        throw context.error(
          at: binding.pattern,
          message: .expectedBindingIdentifier(),
          fixIts: .insertBindingIdentifier(node: binding.pattern))
      } else {
        throw context.error(
          at: binding.pattern,
          message: .internalError())
      }
    }

    // Binding identifier must not be "_" (implicitly named).
    guard identifierPattern.identifier.tokenKind != .wildcard else {
      // FIXME: never reached
      throw context.error(
        at: binding.pattern,
        message: .expectedBindingIdentifier(),
        fixIts: .insertBindingIdentifier(node: binding.pattern))
    }

    // Binding must have a type annotation.
    let type = try binding.requireType(context)

    // Binding type must be a simple identifier; not an optional, tuple,
    // array, etc...
    if let typeIdentifier = type.as(IdentifierTypeSyntax.self) {
      // Binding type must not be "_" (implicitly typed).
      guard typeIdentifier.name.tokenKind != .wildcard else {
        throw context.error(
          at: type,
          message: .unexpectedInferredType(),
          fixIts: .insertBindingType(node: binding))
      }
    } else if type.is(MemberTypeSyntax.self) {
      // Ok
    } else {
      throw context.error(
        at: type,
        message: .unexpectedBindingType())
    }

    // Binding must not have any accessors.
    try binding.requireNoAccessor(context)

    return [
      """
      @inlinable @inline(__always) get {
        #if FEATURE_INTERPOSABLE
        return .init(unsafeAddress: self.unsafeAddress + (\(raw: self.$offset)), interposer: self.interposer)
        #else
        return .init(unsafeAddress: self.unsafeAddress + (\(raw: self.$offset)))
        #endif
      }
      """
    ]
  }
}
