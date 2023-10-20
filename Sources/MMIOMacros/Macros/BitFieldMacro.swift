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

// @BaseName(bits: 3..<4, 0..<1, as: Bool.self)
protocol BitFieldMacro: MMIOAccessorMacro, ParsableMacro {
  static var isReadable: Bool { get }
  static var isWriteable: Bool { get }
  static var isSymmetric: Bool { get }

  var bitRanges: [Range<Int>] { get }
  var bitRangeExpressions: [ExprSyntax] { get }

  var projectedType: Int? { get }
}

extension BitFieldMacro {
  func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [AccessorDeclSyntax] {
    // Can only applied to variables.
    guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
      context.error(
        at: declaration,
        message: .expectedVarDecl())
      return []
    }

    // Must be `var` binding.
    try variableDecl.require(bindingKind: .var, context)

    // Exactly one binding for the variable.
    let binding = try variableDecl.requireSingleBinding(context)

    // Binding identifier must be a simple identifier
    guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
      if binding.pattern.is(TuplePatternSyntax.self) {
        // Binding identifier must not be a tuple.
        context.error(
          at: binding.pattern,
          message: .unexpectedTupleBindingIdentifier())
        return []
      } else if binding.pattern.is(WildcardPatternSyntax.self) {
        context.error(
          at: binding.pattern,
          message: .expectedBindingIdentifier(),
          fixIts: .insertBindingIdentifier(node: binding.pattern))
        return []
      } else {
        context.error(
          at: binding.pattern,
          message: .internalError())
        return []
      }
    }

    // Binding identifier must not be "_" (implicitly named).
    guard identifierPattern.identifier.tokenKind != .wildcard else {
      // FIXME: never reached
      context.error(
        at: binding.pattern,
        message: .expectedBindingIdentifier(),
        fixIts: .insertBindingIdentifier(node: binding.pattern))
      return []
    }

    // Binding must have a type annotation.
    let type = try binding.requireType(context)

    // Binding type must be a simple identifier; not an optional, tuple,
    // array, etc...
    if let typeIdentifier = type.as(IdentifierTypeSyntax.self) {
      // Binding type must not be "_" (implicitly typed).
      guard typeIdentifier.name.tokenKind != .wildcard else {
        context.error(
          at: type,
          message: .unexpectedInferredType(),
          fixIts: .insertBindingType(node: binding))
        return []
      }
    } else if type.is(MemberTypeSyntax.self) {
      // Ok
    } else {
      context.error(
        at: type,
        message: .unexpectedBindingType())
      return []
    }

    // Binding must not have any accessors.
    try binding.requireNoAccessor(context)

    return ["get { fatalError() }"]
  }
}

let bitFieldMacros: [any BitFieldMacro.Type] = [
  ReservedMacro.self,
  ReadWriteMacro.self,
  ReadOnlyMacro.self,
  WriteOnlyMacro.self,
]

struct ReservedMacro: BitFieldMacro, Sendable {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "Reserved"
  static let isReadable = false
  static let isWriteable = false
  static let isSymmetric = true

  @Argument(label: "bits")
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

  var projectedType: Int?

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    switch label {
    case "bits":
      try self._bitRanges.update(from: expression, in: context)
    default:
      fatalError()
    }
  }
}

struct ReadWriteMacro: BitFieldMacro, Sendable {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "ReadWrite"
  static let isReadable = true
  static let isWriteable = true
  static let isSymmetric = true

  @Argument(label: "bits")
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

  @Argument(label: "as")
  var projectedType: Int?

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    switch label {
    case "bits":
      try self._bitRanges.update(from: expression, in: context)
    case "as":
      try self._projectedType.update(from: expression, in: context)
    default:
      fatalError()
    }
  }
}

struct ReadOnlyMacro: BitFieldMacro, Sendable {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "ReadOnly"
  static let isReadable = true
  static let isWriteable = false
  static let isSymmetric = false

  @Argument(label: "bits")
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

  @Argument(label: "as")
  var projectedType: Int?

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    switch label {
    case "bits":
      try self._bitRanges.update(from: expression, in: context)
    case "as":
      try self._projectedType.update(from: expression, in: context)
    default:
      fatalError()
    }
  }
}

struct WriteOnlyMacro: BitFieldMacro, Sendable {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "WriteOnly"
  static let isReadable = false
  static let isWriteable = true
  static let isSymmetric = false

  @Argument(label: "bits")
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

  @Argument(label: "as")
  var projectedType: Int?

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    switch label {
    case "bits":
      try self._bitRanges.update(from: expression, in: context)
    case "as":
      try self._projectedType.update(from: expression, in: context)
    default:
      fatalError()
    }
  }
}
