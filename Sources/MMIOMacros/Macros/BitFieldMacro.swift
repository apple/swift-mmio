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

struct BitField {
  var type: any BitFieldMacro.Type
  var fieldName: IdentifierPatternSyntax
  var fieldTypeName: TypeSyntax
  var bitRange: ExprSyntax
  var projectedTypeName: ExprSyntax?
}

struct BitFieldMacroArguments: ParsableMacroArguments {
  var bits: ExprSyntax
  var asType: ExprSyntax?

  init(arguments: [ExprSyntax]) {
    self.bits = arguments[0]
  }
}

// @BaseName(bits: 0..<1, as: Bool.self)
protocol BitFieldMacro: MMIOAccessorMacro, ParsableMacro
where Self.Arguments == BitFieldMacroArguments {
  static var isReadable: Bool { get }
  static var isWriteable: Bool { get }
  static var isSymmetric: Bool { get }
}

extension BitFieldMacro {
  static var arguments: [(label: String, type: String)] {
    [("bits", "Range<Int>")]
  }
}

extension BitFieldMacro {
  static func mmioExpansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    let context = MacroContext(Self.self, context)

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
  typealias Arguments = BitFieldMacroArguments
  static var baseName = "Reserved"
  static var isReadable: Bool { false }
  static var isWriteable: Bool { false }
  static var isSymmetric: Bool { true }
}

struct ReadWriteMacro: BitFieldMacro, Sendable {
  typealias Arguments = BitFieldMacroArguments
  static var baseName = "ReadWrite"
  static var isReadable: Bool { true }
  static var isWriteable: Bool { true }
  static var isSymmetric: Bool { true }
}

struct ReadOnlyMacro: BitFieldMacro, Sendable {
  typealias Arguments = BitFieldMacroArguments
  static var baseName = "ReadOnly"
  static var isReadable: Bool { true }
  static var isWriteable: Bool { false }
  static var isSymmetric: Bool { false }
}

struct WriteOnlyMacro: BitFieldMacro, Sendable {
  typealias Arguments = BitFieldMacroArguments
  static var baseName = "WriteOnly"
  static var isReadable: Bool { false }
  static var isWriteable: Bool { true }
  static var isSymmetric: Bool { false }
}
