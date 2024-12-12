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

final class RegisterBlockMacroTests: XCTestCase {
  typealias ErrorDiagnostic = MMIOMacros.ErrorDiagnostic<RegisterBlockMacro>

  static let macros: [String: Macro.Type] = [
    "RegisterBlock": RegisterBlockMacro.self
  ]
  static let indentationWidth = Trivia.spaces(2)

  func test_decl_onlyStruct() {
    assertMacroExpansion(
      """
      @RegisterBlock actor A {}
      @RegisterBlock class C {}
      @RegisterBlock enum E {}
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
          column: 16,
          highlights: ["actor"]),
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 2,
          column: 16,
          highlights: ["class"]),
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 3,
          column: 16,
          highlights: ["enum"]),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_decl_onlyStruct_broken() {
    assertMacroExpansion(
      """
      @RegisterBlock var v: Int
      """,
      expandedSource: """
        var v: Int
        """,
      diagnostics: [
        // FIXME: https://github.com/swiftlang/swift-syntax/issues/2206
      ],
      macros: Self.macros)
  }

  func test_members_storedVarDeclsAreAnnotated() {
    assertMacroExpansion(
      """
      @RegisterBlock
      struct S {
        var v1: Int
        @OtherAttribute var v2: Int
        var v3: Int { willSet {} }
      }
      """,
      expandedSource: """
        struct S {
          var v1: Int
          @OtherAttribute var v2: Int
          var v3: Int { willSet {} }
        }

        extension S: RegisterProtocol {
        }
        """,
      diagnostics: [
        .init(
          message:
            ErrorDiagnostic.expectedMemberAnnotatedWithMacro(
              registerBlockMemberMacros
            ).message,
          line: 3,
          column: 3,
          highlights: ["var v1: Int"],
          fixIts: [
            .init(message: "Insert '@RegisterBlock(offset:)' macro"),
            .init(
              message: "Insert '@RegisterBlock(offset:stride:count:)' macro"),
          ]),
        .init(
          message:
            ErrorDiagnostic.expectedMemberAnnotatedWithMacro(
              registerBlockMemberMacros
            ).message,
          line: 4,
          column: 3,
          highlights: ["@OtherAttribute var v2: Int"],
          fixIts: [
            .init(message: "Insert '@RegisterBlock(offset:)' macro"),
            .init(
              message: "Insert '@RegisterBlock(offset:stride:count:)' macro"),
          ]),
        .init(
          message:
            ErrorDiagnostic.expectedMemberAnnotatedWithMacro(
              registerBlockMemberMacros
            ).message,
          line: 5,
          column: 3,
          highlights: ["var v3: Int { willSet {} }"],
          fixIts: [
            .init(message: "Insert '@RegisterBlock(offset:)' macro"),
            .init(
              message: "Insert '@RegisterBlock(offset:stride:count:)' macro"),
          ]),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_members_nonStoredVarDeclsAreOk() {
    assertMacroExpansion(
      """
      @RegisterBlock
      struct S {
        func f() {}
        class C {}
        var v: Void {}
        var v: Void { get {} }
        var v: Void { set {} }
        var v: Void { _read {} }
        var v: Void { _modify {} }
      }
      """,
      expandedSource: """
        struct S {
          func f() {}
          class C {}
          var v: Void {}
          var v: Void { get {} }
          var v: Void { set {} }
          var v: Void { _read {} }
          var v: Void { _modify {} }

          let unsafeAddress: UInt

          #if FEATURE_INTERPOSABLE
          var interposer: (any MMIOInterposer)?
          #endif

          #if FEATURE_INTERPOSABLE
          @inlinable @inline(__always)
          init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?) {
            self.unsafeAddress = unsafeAddress
            self.interposer = interposer
          }
          #else
          @inlinable @inline(__always)
          init(unsafeAddress: UInt) {
            self.unsafeAddress = unsafeAddress
          }
          #endif
        }

        extension S: RegisterProtocol {
        }
        """,
      diagnostics: [],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
#endif
