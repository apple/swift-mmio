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
protocol MMIOAccessorMacro: AccessorMacro {
  static func mmioExpansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax]
}

extension MMIOAccessorMacro {
  /// Calls the mmioExpansion customization point.
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) -> [AccessorDeclSyntax] {
    do {
      return try Self.mmioExpansion(
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
