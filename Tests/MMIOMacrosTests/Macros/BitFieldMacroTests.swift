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
import SwiftSyntaxMacros
import Testing

@testable import MMIOMacros

struct BitFieldMacroTests {
  struct TestMacro: BitFieldMacro {
    static let accessorMacroSuppressParsingDiagnostics = false
    static let baseName = "Test"
    static let isReadable = true
    static let isWriteable = true
    static let isSymmetric = true

    @Argument(label: "bits")
    var bitRanges: [BitRange]
    var bitRangeExpressions: [ExprSyntax] { self.$bitRanges }

    @Argument(label: "as")
    var projectedType: BitFieldTypeProjection?

    mutating func update(
      label: String,
      from expression: ExprSyntax,
      in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
    ) throws {
      switch label {
      case "bits":
        try self._bitRanges.update(from: expression, in: context)
      case "as":
        try self._projectedType.update(from: expression, in: context)
      default:
        fatalError()
      }
    }
  }

  typealias ErrorDiagnostic = MMIOMacros.ErrorDiagnostic<TestMacro>

  static let macros: [String: SendableMacro.Type] = [
    "Test": TestMacro.self
  ]
  static let indentationWidth = Trivia.spaces(2)

  @Test func decl_onlyVar() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) struct S {}
      @Test(bits: 0..<1) func f() {}
      """,
      expandedSource: """
        struct S {}
        func f() {}
        """,
      diagnostics: [
        // FIXME: https://github.com/swiftlang/swift-syntax/issues/2207
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func binding_onlyVar() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) inout a: Int
      @Test(bits: 0..<1) let b: Int
      """,
      expandedSource: """
        inout a: Int
        let b: Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedBindingSpecifier(.var).message,
          line: 1,
          column: 20,
          highlights: ["inout"],
          fixIts: [
            .init(message: "Replace 'inout' with 'var'")
          ]),
        .init(
          message: ErrorDiagnostic.expectedBindingSpecifier(.var).message,
          line: 2,
          column: 20,
          highlights: ["let"],
          fixIts: [
            .init(message: "Replace 'let' with 'var'")
          ]),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func binding_noMultiple() {
    let message = "accessor macro can only be applied to a single variable"
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var a, b: Int
      @Test(bits: 0..<1) var c: Int, d: Int
      """,
      expandedSource: """
        var a, b: Int
        var c: Int, d: Int
        """,
      diagnostics: [
        .init(message: message, line: 1, column: 1),
        .init(message: message, line: 2, column: 1),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingIdentifier_noImplicit() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var _: Int
      """,
      expandedSource: """
        var _: Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingIdentifier().message,
          line: 1,
          column: 24,
          highlights: ["_"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingIdentifier_noTuple() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var (a, b): Int
      """,
      expandedSource: """
        var (a, b): Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingIdentifier().message,
          line: 1,
          column: 24,
          highlights: ["(a, b)"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingType_noOmitted() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var v
      """,
      expandedSource: """
        var v
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 24,
          highlights: ["v"],
          fixIts: [
            .init(message: "Insert explicit type annotation")
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingType_noImplicit() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var v: _
      """,
      expandedSource: """
        var v: _
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 27,
          highlights: ["_"],
          fixIts: [
            .init(message: "Insert explicit type annotation")
          ])
      ],

      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingType_noOptional() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var a: Int?
      """,
      expandedSource: """
        var a: Int?
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 27,
          highlights: ["Int?"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingType_noArray() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var a: [Int]
      """,
      expandedSource: """
        var a: [Int]
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 27,
          highlights: ["[Int]"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingType_noTuple() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var a: (Int, Int)
      """,
      expandedSource: """
        var a: (Int, Int)
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 27,
          highlights: ["(Int, Int)"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingType_genericOK() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var a: Reg<T>
      """,
      expandedSource: """
        var a: Reg<T> {
          get {
            fatalError()
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingType_nestedOK() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var a: Swift.Int
      """,
      expandedSource: """
        var a: Swift.Int {
          get {
            fatalError()
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bindingAccessor_omitted() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var a: Int {}
      """,
      expandedSource: """
        var a: Int {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedStoredProperty().message,
          line: 1,
          column: 31,
          highlights: ["{}"],
          fixIts: [
            .init(message: "Remove accessor block")
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func expansion() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var a: Int
      """,
      expandedSource: """
        var a: Int {
          get {
            fatalError()
          }
        }
        """,
      diagnostics: [],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
#endif
