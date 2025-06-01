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

protocol MMIOExtensionMacro: ExtensionMacro, ParsableMacro {
  static var extensionMacroSuppressParsingDiagnostics: Bool { get }

  mutating func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [ExtensionDeclSyntax]
}

extension MMIOExtensionMacro {
  /// Calls the expansion customization point.
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    do {
      let context = MacroContext(Self.self, context)
      var `self`: Self
      if Self.extensionMacroSuppressParsingDiagnostics {
        let context = MacroContext.makeSuppressingDiagnostics(Self.self)
        `self` = try Self(from: node, in: context)
      } else {
        `self` = try Self(from: node, in: context)
      }
      return try self.expansion(
        of: node,
        attachedTo: declaration,
        providingExtensionsOf: type,
        conformingTo: protocols,
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
