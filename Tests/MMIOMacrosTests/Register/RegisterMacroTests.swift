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

final class RegisterMacroTests: XCTestCase {
  let diagnostics = DiagnosticBuilder<RegisterMacro>()

  static let macros: [String: Macro.Type] = [
    "Register": RegisterMacro.self,
    "Reserved": ReservedMacro.self,
    "ReadWrite": ReadWriteMacro.self,
    "ReadOnly": ReadOnlyMacro.self,
    "WriteOnly": WriteOnlyMacro.self,
  ]
  static let indentationWidth = Trivia.spaces(2)

  // FIXME: test bitwidths parsing/allowed widths

  func test_decl_onlyStruct() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8) actor A {}
      @Register(bitWidth: 0x8) class C {}
      @Register(bitWidth: 0x8) enum E {}
      """,
      expandedSource: """
        actor A {}
        class C {}
        enum E {}
        """,
      diagnostics: [
        .init(
          message: diagnostics.onlyStructDecl().message,
          line: 1,
          column: 26,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "actor "),
        .init(
          message: diagnostics.onlyStructDecl().message,
          line: 2,
          column: 26,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "class "),
        .init(
          message: diagnostics.onlyStructDecl().message,
          line: 3,
          column: 26,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "enum "),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_members_onlyVarDecls() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        func f() {}
        class C {}
      }
      """,
      expandedSource: """
        struct S {
          func f() {}
          class C {}
        }
        """,
      diagnostics: [
        .init(
          message: diagnostics.onlyMemberVarDecls().message,
          line: 3,
          column: 3,
          // FIXME: Improve this highlight
          highlight: "func f() {}"),
        .init(
          message: diagnostics.onlyMemberVarDecls().message,
          line: 4,
          column: 3,
          // FIXME: Improve this highlight
          highlight: "class C {}"),

      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_members_varDeclsAreAnnotated() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
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
          message: diagnostics.onlyBitFieldMemberVarDecls().message,
          line: 3,
          column: 3,
          highlight: "var v1: Int"),
        .init(
          message: diagnostics.onlyBitFieldMemberVarDecls().message,
          line: 4,
          column: 3,
          highlight: "@OtherAttribute var v2: Int"),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func testPositiveExample() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @ReadWrite(bits: 0..<1) var v1: V1
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var v1: V1 {
            get {
              fatalError()
            }
          }

          @available(*, unavailable) private init() {
          }

          enum V1: BitField {
                typealias RawStorage = UInt8
                static let bitRange = 0 ..< 1
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite {
                var storage: UInt8
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
