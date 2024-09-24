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

// @BaseName(bits: 3..<4, 0..<1, as: Swift.Bool.self)
protocol BitFieldMacro: MMIOAccessorMacro, ParsableMacro {
  static var isReadable: Bool { get }
  static var isWriteable: Bool { get }
  static var isSymmetric: Bool { get }

  var bitRanges: [BitRange] { get }
  var projectedType: BitFieldTypeProjection? { get }
}

extension BitFieldMacro {
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

    // Binding identifier must be a simple identifier.
    _ = try binding.requireSimpleBindingIdentifier(context)

    // Binding must have a simple type annotation.
    _ = try binding.requireSimpleTypeIdentifier(context)

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

public struct ReservedMacro: BitFieldMacro {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "Reserved"
  static let isReadable = false
  static let isWriteable = false
  static let isSymmetric = true

  @Argument(label: "bits")
  var bitRanges: [BitRange]

  var projectedType: BitFieldTypeProjection?

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

public struct ReadWriteMacro: BitFieldMacro {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "ReadWrite"
  static let isReadable = true
  static let isWriteable = true
  static let isSymmetric = true

  @Argument(label: "bits")
  var bitRanges: [BitRange]

  @Argument(label: "as")
  var projectedType: BitFieldTypeProjection?

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

public struct ReadOnlyMacro: BitFieldMacro {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "ReadOnly"
  static let isReadable = true
  static let isWriteable = false
  static let isSymmetric = false

  @Argument(label: "bits")
  var bitRanges: [BitRange]

  @Argument(label: "as")
  var projectedType: BitFieldTypeProjection?

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

public struct WriteOnlyMacro: BitFieldMacro {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "WriteOnly"
  static let isReadable = false
  static let isWriteable = true
  static let isSymmetric = false

  @Argument(label: "bits")
  var bitRanges: [BitRange]

  @Argument(label: "as")
  var projectedType: BitFieldTypeProjection?

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
