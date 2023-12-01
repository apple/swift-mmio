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
protocol BitFieldMacro: AccessorMacro, ParsableMacro {
  static var isReadable: Bool { get }
  static var isWriteable: Bool { get }
  static var isSymmetric: Bool { get }

  var bitRanges: [Range<Int>] { get }
  var bitRangeExpressions: [ExprSyntax] { get }

  var projectedType: BitFieldTypeProjection? { get }
}

extension BitFieldMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    return ["get { fatalError() }"]
  }
}

let bitFieldMacros: [any BitFieldMacro.Type] = [
  ReservedMacro.self,
  ReadWriteMacro.self,
  ReadOnlyMacro.self,
  WriteOnlyMacro.self,
]

public struct ReservedMacro: BitFieldMacro, Sendable {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "Reserved"
  static let isReadable = false
  static let isWriteable = false
  static let isSymmetric = true

  @Argument(label: "bits")
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

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

public struct ReadWriteMacro: BitFieldMacro, Sendable {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "ReadWrite"
  static let isReadable = true
  static let isWriteable = true
  static let isSymmetric = true

  @Argument(label: "bits")
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

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

public struct ReadOnlyMacro: BitFieldMacro, Sendable {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "ReadOnly"
  static let isReadable = true
  static let isWriteable = false
  static let isSymmetric = false

  @Argument(label: "bits")
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

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

public struct WriteOnlyMacro: BitFieldMacro, Sendable {
  static let accessorMacroSuppressParsingDiagnostics = false
  static let baseName = "WriteOnly"
  static let isReadable = false
  static let isWriteable = true
  static let isSymmetric = false

  @Argument(label: "bits")
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

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
