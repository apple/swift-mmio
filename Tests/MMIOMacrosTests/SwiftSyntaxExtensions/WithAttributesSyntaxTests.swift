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
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import MMIOMacros

final class WithAttributesSyntaxTests: XCTestCase {
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
      in context: MacroContext<Self, some MacroExpansionContext>
    ) throws -> [DeclSyntax] { [] }
  }

  func test_requireMacro() throws {
    struct Vector {
      var decl: any WithAttributesSyntax
      var macros: [any (ParsableMacro.Type)]
      var match: MatchingAttributeAndMacro?
      var file: StaticString
      var line: UInt

      init(
        decl: DeclSyntax,
        macros: [any (ParsableMacro.Type)],
        match: MatchingAttributeAndMacro?,
        file: StaticString = #file,
        line: UInt = #line
      ) {
        self.decl = decl.asProtocol(WithAttributesSyntax.self)!
        self.macros = macros
        self.match = match
        self.file = file
        self.line = line
      }
    }

    let vectors: [Vector] = [
      .init(
        decl: "var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: nil),
      .init(
        decl: "@Other0 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: nil),
      .init(
        decl: "@Other0 @Other1 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: nil),

      .init(
        decl: "@Macro0 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: .init(attribute: "@Macro0", macroType: Macro0.self)),
      .init(
        decl: "@Macro1 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: .init(attribute: "@Macro1", macroType: Macro1.self)),
      .init(
        decl: "@Other0 @Macro0 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: .init(attribute: "@Macro0", macroType: Macro0.self)),
      .init(
        decl: "@Macro0 @Other0 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: .init(attribute: "@Macro0", macroType: Macro0.self)),
      .init(
        decl: "@Other0 @Macro0 @Other0 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: .init(attribute: "@Macro0", macroType: Macro0.self)),

      .init(
        decl: "@Macro0 @Macro1 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: nil),
      .init(
        decl: "@Macro0 @Other0 @Macro1 var v: Bool",
        macros: [Macro0.self, Macro1.self],
        match: nil),

      .init(
        decl: "@Macro0 @Macro1 var v: Bool",
        macros: [Macro0.self],
        match: .init(attribute: "@Macro0", macroType: Macro0.self)),
    ]

    for vector in vectors {
      // FIXME: assert diagnostics
      let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
      do {
        let actual = try vector.decl.requireMacro(vector.macros, context)
        if let expected = vector.match {
          XCTAssertEqual(
            actual.attribute.trimmed.description,
            expected.attribute.trimmed.description,
            file: vector.file,
            line: vector.line)
          XCTAssertEqual(
            actual.macroType.signature,
            expected.macroType.signature,
            file: vector.file,
            line: vector.line)
        } else {
          XCTFail("Unexpectedly found match", file: vector.file, line: vector.line)
        }
      } catch {
        if vector.match != nil {
          XCTFail("Unexpectedly did not find match")
        }
      }
    }
  }
}
