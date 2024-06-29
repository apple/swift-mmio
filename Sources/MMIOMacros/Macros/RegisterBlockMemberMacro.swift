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

protocol RegisterBlockMemberMacro: ParsableMacro {}

extension RegisterBlockMemberMacro {
  func expansion(
    of node: AttributeSyntax,
    offset: ExprSyntax,
    array: (stride: ExprSyntax, count: ExprSyntax)?,
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

    guard let array = array else {
      return [
        """
        @inlinable @inline(__always) get {
          #if FEATURE_INTERPOSABLE
          return .init(unsafeAddress: self.unsafeAddress + (\(offset)), interposer: self.interposer)
          #else
          return .init(unsafeAddress: self.unsafeAddress + (\(offset)))
          #endif
        }
        """
      ]
    }
    return [
      """
      @inlinable @inline(__always) get {
        #if FEATURE_INTERPOSABLE
        return .init(unsafeAddress: self.unsafeAddress + (\(offset)), stride: \(array.stride), count: \(array.count), interposer: self.interposer)
        #else
        return .init(unsafeAddress: self.unsafeAddress + (\(offset)), stride: \(array.stride), count: \(array.count))
        #endif
      }
      """
    ]
  }
}

let registerBlockMemberMacros: [any RegisterBlockMemberMacro.Type] = [
  RegisterBlockScalarMemberMacro.self,
  RegisterBlockArrayMemberMacro.self,
]

public struct RegisterBlockScalarMemberMacro {
  @Argument(label: "offset")
  var offset: Int
}

extension RegisterBlockScalarMemberMacro: ParsableMacro {
  static let baseName = "RegisterBlock"

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

extension RegisterBlockScalarMemberMacro: MMIOAccessorMacro {
  static var accessorMacroSuppressParsingDiagnostics: Bool { false }

  func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [AccessorDeclSyntax] {
    try self.expansion(
      of: node,
      offset: self.$offset,
      array: nil,
      providingAccessorsOf: declaration,
      in: context)
  }
}

extension RegisterBlockScalarMemberMacro: RegisterBlockMemberMacro {}

public struct RegisterBlockArrayMemberMacro {
  @Argument(label: "offset")
  var offset: Int
  @Argument(label: "stride")
  var stride: Int
  @Argument(label: "count")
  var count: Int
}

extension RegisterBlockArrayMemberMacro: ParsableMacro {
  static let baseName = "RegisterBlock"

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    switch label {
    case "offset":
      try self._offset.update(from: expression, in: context)
    case "stride":
      try self._stride.update(from: expression, in: context)
    case "count":
      try self._count.update(from: expression, in: context)
    default:
      fatalError()
    }
  }
}

extension RegisterBlockArrayMemberMacro: MMIOAccessorMacro {
  static var accessorMacroSuppressParsingDiagnostics: Bool { false }

  func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [AccessorDeclSyntax] {
    try self.expansion(
      of: node,
      offset: self.$offset,
      array: (stride: self.$stride, count: self.$count),
      providingAccessorsOf: declaration,
      in: context)
  }
}

extension RegisterBlockArrayMemberMacro: RegisterBlockMemberMacro {}
