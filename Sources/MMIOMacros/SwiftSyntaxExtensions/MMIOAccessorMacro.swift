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

import SwiftSyntax
import SwiftSyntaxMacros

/// Wrapper around AccessorMacro used to suppress thrown expansion errors.
protocol MMIOAccessorMacro: AccessorMacro, ParsableMacro {
  static var accessorMacroSuppressParsingDiagnostics: Bool { get }

  mutating func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [AccessorDeclSyntax]
}

extension MMIOAccessorMacro {
  /// Calls the expansion instance method customization point.
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) -> [AccessorDeclSyntax] {
    do {
      let context = MacroContext(Self.self, context)
      var `self`: Self
      if Self.accessorMacroSuppressParsingDiagnostics {
        let context = MacroContext.makeSuppressingDiagnostics(Self.self)
        `self` = try Self(from: node, in: context)
      } else {
        `self` = try Self(from: node, in: context)
      }
      return try self.expansion(
        of: node,
        providingAccessorsOf: declaration,
        in: context)
    } catch is ExpansionError {
      // Hide expansion error from user, the function which generated the error
      // should have injected a diagnostic into context.
      return []
    } catch {
      fatalError()
    }
  }
}
