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
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import MMIOMacros

final class RegisterBlockOffsetMacroTests: XCTestCase {
  typealias ErrorDiagnostic = MMIOMacros.ErrorDiagnostic<
    RegisterBlockScalarMemberMacro
  >

  static let macros: [String: Macro.Type] = [
    "RegisterBlock": RegisterBlockScalarMemberMacro.self
  ]
  static let indentationWidth = Trivia.spaces(2)

  func test_decl_onlyVar() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) struct S {}
      @RegisterBlock(offset: 0x0) func f() {}
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

  func test_binding_onlyVar() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) inout a: Int
      @RegisterBlock(offset: 0x0) let b: Int
      """,
      expandedSource: """
        inout a: Int
        let b: Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedBindingSpecifier(.var).message,
          line: 1,
          column: 29,
          highlights: ["inout"],
          fixIts: [
            .init(message: "Replace 'inout' with 'var'")
          ]),
        .init(
          message: ErrorDiagnostic.expectedBindingSpecifier(.var).message,
          line: 2,
          column: 29,
          highlights: ["let"],
          fixIts: [
            .init(message: "Replace 'let' with 'var'")
          ]),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_binding_noMultiple() {
    let message = "accessor macro can only be applied to a single variable"
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) var a, b: Int
      @RegisterBlock(offset: 0x0) var c: Int, d: Int
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
      @RegisterBlock(offset: 0x0) var _: Int
      """,
      expandedSource: """
        var _: Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingIdentifier().message,
          line: 1,
          column: 33,
          highlights: ["_"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingIdentifier_noTuple() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) var (a, b): Int
      """,
      expandedSource: """
        var (a, b): Int
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingIdentifier().message,
          line: 1,
          column: 33,
          highlights: ["(a, b)"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noOmitted() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) var v
      """,
      expandedSource: """
        var v
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 33,
          highlights: ["v"],
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
      @RegisterBlock(offset: 0x0) var v: _
      """,
      expandedSource: """
        var v: _
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 36,
          highlights: ["_"],
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
      @RegisterBlock(offset: 0x0) var a: Int?
      """,
      expandedSource: """
        var a: Int?
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 36,
          highlights: ["Int?"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noArray() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) var a: [Int]
      """,
      expandedSource: """
        var a: [Int]
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 36,
          highlights: ["[Int]"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_noTuple() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) var a: (Int, Int)
      """,
      expandedSource: """
        var a: (Int, Int)
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.unexpectedBindingType().message,
          line: 1,
          column: 36,
          highlights: ["(Int, Int)"])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_genericOK() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) var a: Reg<T>
      """,
      expandedSource: """
        var a: Reg<T> {
          @inlinable @inline(__always) get {
            #if FEATURE_INTERPOSABLE
            return .init(unsafeAddress: self.unsafeAddress + (0x0), interposer: self.interposer)
            #else
            return .init(unsafeAddress: self.unsafeAddress + (0x0))
            #endif
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingType_nestedOK() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) var a: Swift.Int
      """,
      expandedSource: """
        var a: Swift.Int {
          @inlinable @inline(__always) get {
            #if FEATURE_INTERPOSABLE
            return .init(unsafeAddress: self.unsafeAddress + (0x0), interposer: self.interposer)
            #else
            return .init(unsafeAddress: self.unsafeAddress + (0x0))
            #endif
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_bindingAccessor_omitted() {
    assertMacroExpansion(
      """
      @RegisterBlock(offset: 0x0) var a: Int {}
      """,
      expandedSource: """
        var a: Int {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedStoredProperty().message,
          line: 1,
          column: 40,
          highlights: ["{}"],
          fixIts: [
            .init(message: "Remove accessor block")
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
#endif
