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

#if canImport(MMIOMacros)
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

@testable import MMIOMacros

struct Macro0: MMIOMemberMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool { false }

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {}

  mutating func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] { [] }
}

struct Macro1: MMIOMemberMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool { false }

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {}

  mutating func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] { [] }
}
#endif
