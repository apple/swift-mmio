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

#if canImport(MMIOMacros)
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

@testable import MMIOMacros

struct WithAttributesSyntaxTests {
  struct RequireMacroTestVector: CustomStringConvertible {
    static let vectors: [Self] = [
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

    var description: String { "\(self.decl)" }
    var decl: any WithAttributesSyntax
    var macros: [any (ParsableMacro.Type)]
    var match: MatchingAttributeAndMacro?

    init(
      decl: DeclSyntax,
      macros: [any (ParsableMacro.Type)],
      match: MatchingAttributeAndMacro?
    ) {
      // swift-format-ignore: NeverForceUnwrap
      self.decl = decl.asProtocol(WithAttributesSyntax.self)!
      self.macros = macros
      self.match = match
    }
  }

  @Test(arguments: RequireMacroTestVector.vectors)
  func requireMacro(vector: RequireMacroTestVector) throws {
    // FIXME: assert diagnostics
    let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
    let actual = try? vector.decl.requireMacro(vector.macros, context)
    let expected = vector.match
    #expect(
      actual?.attribute.trimmed.description
        == expected?.attribute.trimmed.description)
    #expect(actual?.macroType.signature == expected?.macroType.signature)
  }
}
#endif
