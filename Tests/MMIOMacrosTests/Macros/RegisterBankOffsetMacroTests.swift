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

final class RegisterBankOffsetMacroTests: XCTestCase {
  typealias ErrorDiagnostic = MMIOMacros.ErrorDiagnostic<RegisterBankOffsetMacro>

  static let macros: [String: Macro.Type] = [
    "RegisterBank": RegisterBankOffsetMacro.self
  ]
  static let indentationWidth = Trivia.spaces(2)

  func test_decl_onlyVar() {
    assertMacroExpansion(
      """
      @RegisterBank(offset: 0x0) struct S {}
      @RegisterBank(offset: 0x0) func f() {}
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
      @RegisterBank(offset: 0x0) inout a: Int
      @RegisterBank(offset: 0x0) let b: Int
      """,
      expandedSource: """
        inout a: Int
        let b: Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedBindingKind(.var).message,
          line: 1,
          column: 28,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "inout ",
          fixIts: [
            .init(message: "Replace 'inout' with 'var'")
          ]),
        .init(
          message: ErrorDiagnostic.expectedBindingKind(.var).message,
          line: 2,
          column: 28,
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
      @RegisterBank(offset: 0x0) var a, b: Int
      @RegisterBank(offset: 0x0) var c: Int, d: Int
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
      @RegisterBank(offset: 0x0) var _: Int
      """,
      expandedSource: """
        var _: Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedBindingIdentifier().message,
          line: 1,
          column: 32,
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
      @RegisterBank(offset: 0x0) var (a, b): (Int, Int)
      """,
      expandedSource: """
        var (a, b): (Int, Int)
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedTupleBindingIdentifier().message,
          line: 1,
          column: 32,
          highlight: "(a, b)")
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noOmitted() {
    assertMacroExpansion(
      """
      @RegisterBank(offset: 0x0) var v
      """,
      expandedSource: """
        var v
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedTypeAnnotation().message,
          line: 1,
          column: 32,
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
      @RegisterBank(offset: 0x0) var v: _
      """,
      expandedSource: """
        var v: _
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedInferredType().message,
          line: 1,
          column: 35,
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
      @RegisterBank(offset: 0x0) var a: Int?
      """,
      expandedSource: """
        var a: Int?
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 35,
          highlight: "Int?")
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noArray() {
    assertMacroExpansion(
      """
      @RegisterBank(offset: 0x0) var a: [Int]
      """,
      expandedSource: """
        var a: [Int]
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 35,
          highlight: "[Int]")
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noTuple() {
    assertMacroExpansion(
      """
      @RegisterBank(offset: 0x0) var a: (Int, Int)
      """,
      expandedSource: """
        var a: (Int, Int)
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 35,
          highlight: "(Int, Int)")
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_genericOK() {
    assertMacroExpansion(
      """
      @RegisterBank(offset: 0x0) var a: Reg<T>
      """,
      expandedSource: """
        var a: Reg<T> {
          @inline(__always) get {
            .init(unsafeAddress: self.unsafeAddress + (0x0))
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_nestedOK() {
    assertMacroExpansion(
      """
      @RegisterBank(offset: 0x0) var a: Swift.Int
      """,
      expandedSource: """
        var a: Swift.Int {
          @inline(__always) get {
            .init(unsafeAddress: self.unsafeAddress + (0x0))
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingAccessor_omitted() {
    assertMacroExpansion(
      """
      @RegisterBank(offset: 0x0) var a: Int {}
      """,
      expandedSource: """
        var a: Int {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedStoredProperty().message,
          line: 1,
          column: 39,
          highlight: "{}",
          fixIts: [
            .init(message: "Remove accessor block")
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
