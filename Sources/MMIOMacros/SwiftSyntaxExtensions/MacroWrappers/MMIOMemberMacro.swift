//===----------------------------------------------------------------------===//
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

protocol MMIOMemberMacro: MemberMacro, ParsableMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool { get }

  mutating func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax]
}

extension MMIOMemberMacro {
  /// Calls the expansion customization point.
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    do {
      let context = MacroContext(Self.self, context)
      var `self`: Self
      if Self.memberMacroSuppressParsingDiagnostics {
        let context = MacroContext.makeSuppressingDiagnostics(Self.self)
        `self` = try Self(from: node, in: context)
      } else {
        `self` = try Self(from: node, in: context)
      }
      return try self.expansion(
        of: node,
        providingMembersOf: declaration,
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
