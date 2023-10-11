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
import XCTest

@testable import MMIOMacros

protocol MMIOArgumentParsingMacro: ParsableMacro, MMIOMemberMacro {}
extension MMIOArgumentParsingMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool { false }
  mutating func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] { [] }
}
