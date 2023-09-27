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

final class RegisterBankMacroTests: XCTestCase {
  typealias ErrorDiagnostic = MMIOMacros.ErrorDiagnostic<RegisterBankMacro>

  static let macros: [String: Macro.Type] = [
    "RegisterBank": RegisterBankMacro.self
  ]
  static let indentationWidth = Trivia.spaces(2)

  func test_decl_onlyStruct() {
    assertMacroExpansion(
      """
      @RegisterBank actor A {}
      @RegisterBank class C {}
      @RegisterBank enum E {}
      """,
      expandedSource: """
        actor A {}
        class C {}
        enum E {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 1,
          column: 15,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "actor "),
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 2,
          column: 15,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "class "),
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 3,
          column: 15,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "enum "),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_members_varDeclsAreAnnotated() {
    assertMacroExpansion(
      """
      @RegisterBank
      struct S {
        var v1: Int
        @OtherAttribute var v2: Int
      }
      """,
      expandedSource: """
        struct S {
          var v1: Int
          @OtherAttribute var v2: Int
        }
        """,
      diagnostics: [
        .init(
          message:
            ErrorDiagnostic
            .expectedMemberAnnotatedWithMacro(RegisterBankOffsetMacro.self)
            .message,
          line: 3,
          column: 3,
          highlight: "var v1: Int",
          fixIts: [
            .init(message: "Insert '@RegisterBank(offset:)' macro")
          ]),
        .init(
          message:
            ErrorDiagnostic
            .expectedMemberAnnotatedWithMacro(RegisterBankOffsetMacro.self)
            .message,
          line: 4,
          column: 3,
          highlight: "@OtherAttribute var v2: Int",
          fixIts: [
            .init(message: "Insert '@RegisterBank(offset:)' macro")
          ]),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_members_nonVarDeclIsOk() {
    assertMacroExpansion(
      """
      @RegisterBank
      struct S {
        func f() {}
        class C {}
      }
      """,
      expandedSource: """
        struct S {
          func f() {}
          class C {}

          private (set) var unsafeAddress: UInt

          init(unsafeAddress: UInt) {
            self.unsafeAddress = unsafeAddress
          }
        }
        """,
      diagnostics: [],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
