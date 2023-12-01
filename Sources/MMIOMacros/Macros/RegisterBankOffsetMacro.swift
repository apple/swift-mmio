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
    return [
      """
      @inlinable @inline(__always) get {
        #if FEATURE_INTERPOSABLE
        return .init(unsafeAddress: self.unsafeAddress + (\(self.$offset)), interposer: self.interposer)
        #else
        return .init(unsafeAddress: self.unsafeAddress + (\(self.$offset)))
        #endif
      }
      """
    ]
  }
}
