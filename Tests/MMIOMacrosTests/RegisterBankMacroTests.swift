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
  typealias Diagnostics = RegisterBankMacro.Diagnostics

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
          message: Diagnostics.Errors.onlyStructDecl().message,
          line: 1,
          column: 15,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "actor "),
        .init(
          message: Diagnostics.Errors.onlyStructDecl().message,
          line: 2,
          column: 15,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "class "),
        .init(
          message: Diagnostics.Errors.onlyStructDecl().message,
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
          message: Diagnostics.Errors.onlyAnnotatedMemberVarDecls().message,
          line: 3,
          column: 3,
          highlight: "var v1: Int"),
        .init(
          message: Diagnostics.Errors.onlyAnnotatedMemberVarDecls().message,
          line: 4,
          column: 3,
          highlight: "@OtherAttribute var v2: Int"),
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
        struct S {}
      }
      """,
      expandedSource: """
        struct S {
          func f() {}
          struct S {}

          var unsafeAddress: UInt

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
