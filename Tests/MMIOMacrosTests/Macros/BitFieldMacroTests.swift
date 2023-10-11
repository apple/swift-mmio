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
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import MMIOMacros

final class BitFieldMacroTests: XCTestCase {
  struct TestMacro: BitFieldMacro {
    static var accessorMacroSuppressParsingDiagnostics: Bool { false }
    static var baseName: String { "Test" }
    static var isReadable: Bool { true }
    static var isWriteable: Bool { true }
    static var isSymmetric: Bool { true }

    var bits: Range<Int>
    var asType: Void?

    init(arguments: Arguments) {
      self.bits = arguments.bits
      self.asType = arguments.asType
    }
  }

  typealias ErrorDiagnostic = MMIOMacros.ErrorDiagnostic<TestMacro>

  static let macros: [String: Macro.Type] = [
    "Test": TestMacro.self
  ]
  static let indentationWidth = Trivia.spaces(2)

  func test_decl_onlyVar() {
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
        // FIXME: https://github.com/apple/swift-syntax/issues/2207
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_binding_onlyVar() {
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
          message: ErrorDiagnostic.expectedBindingKind(.var).message,
          line: 1,
          column: 20,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "inout ",
          fixIts: [
            .init(message: "Replace 'inout' with 'var'")
          ]),
        .init(
          message: ErrorDiagnostic.expectedBindingKind(.var).message,
          line: 2,
          column: 20,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "let ",
          fixIts: [
            .init(message: "Replace 'let' with 'var'")
          ]),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_binding_noMultiple() {
    let message = """
      swift-syntax applies macros syntactically and there is no way to \
      represent a variable declaration with multiple bindings that have \
      accessors syntactically. While the compiler allows this expansion, \
      swift-syntax cannot represent it and thus disallows it.
      """
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

  func test_bindingIdentifier_noImplicit() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var _: Int
      """,
      expandedSource: """
        var _: Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedBindingIdentifier().message,
          line: 1,
          column: 24,
          highlight: "_",
          fixIts: [
            .init(message: "Insert explicit property identifier")
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingIdentifier_noTuple() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var (a, b): (Int, Int)
      """,
      expandedSource: """
        var (a, b): (Int, Int)
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedTupleBindingIdentifier().message,
          line: 1,
          column: 24,
          highlight: "(a, b)")
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noOmitted() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var v
      """,
      expandedSource: """
        var v
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedTypeAnnotation().message,
          line: 1,
          column: 24,
          highlight: "v",
          fixIts: [
            .init(message: "Insert explicit type annotation")
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noImplicit() {
    assertMacroExpansion(
      """
      @Test(bits: 0..<1) var v: _
      """,
      expandedSource: """
        var v: _
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedInferredType().message,
          line: 1,
          column: 27,
          highlight: "_",
          fixIts: [
            .init(message: "Insert explicit type annotation")
          ])
      ],

      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noOptional() {
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
          highlight: "Int?")
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noArray() {
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
          highlight: "[Int]")
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noTuple() {
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
          highlight: "(Int, Int)")
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_genericOK() {
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

  func test_bindingType_nestedOK() {
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

  func test_bindingAccessor_omitted() {
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
          highlight: "{}",
          fixIts: [
            .init(message: "Remove accessor block")
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion() {
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
