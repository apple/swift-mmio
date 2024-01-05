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

protocol MMIOArgumentParsingMacro: MMIOMemberMacro {}
extension MMIOArgumentParsingMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool { false }
  mutating func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] { [] }
}

final class ParsableMacroTests: XCTestCase {
  func test_noArguments_parse() {
    struct A: MMIOArgumentParsingMacro {
      mutating func update(
        label: String,
        from expression: ExprSyntax,
        in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
      ) throws {
        fatalError()
      }
    }

    // Good...
    assertMacroExpansion(
      """
      @A struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A() struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    // Bad...
    assertMacroExpansion(
      """
      @A(0) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "_").message,
          line: 1,
          column: 4,
          highlight: "0")
      ],
      macros: ["A": A.self])
  }

  func test_oneArgument_parse() {
    struct A: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var bar: Int

      mutating func update(
        label: String,
        from expression: ExprSyntax,
        in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
      ) throws {
        switch label {
        case "foo":
          try self._bar.update(from: expression, in: context)
        default:
          fatalError()
        }
      }
    }

    // Good...
    assertMacroExpansion(
      """
      @A(foo: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    // Bad...
    assertMacroExpansion(
      """
      @A struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedMissingArgument(label: "foo").message,
          line: 1,
          column: 1,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "@A ")
      ],
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A() struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedMissingArgument(label: "foo").message,
          line: 1,
          column: 1,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "@A() ")
      ],
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A(bar: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedArgumentLabel(expected: "foo", actual: "bar").message,
          line: 1,
          column: 4,
          highlight: "bar: 1")
      ],
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A(foo: 1, baz: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "baz").message,
          line: 1,
          column: 12,
          highlight: "baz: 1")
      ],
      macros: ["A": A.self])
  }

  func test_oneArgumentOptional_parse() {
    struct A: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var bar: Int?

      mutating func update(
        label: String,
        from expression: ExprSyntax,
        in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
      ) throws {
        switch label {
        case "foo":
          try self._bar.update(from: expression, in: context)
        default:
          fatalError()
        }
      }
    }

    // Good...
    assertMacroExpansion(
      """
      @A(foo: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A() struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    // Bad...
    assertMacroExpansion(
      """
      @A(bar: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedArgumentLabel(expected: "foo", actual: "bar").message,
          line: 1,
          column: 4,
          highlight: "bar: 1")
      ],
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A(foo: 1, baz: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "baz").message,
          line: 1,
          column: 12,
          highlight: "baz: 1")
      ],
      macros: ["A": A.self])

    // FIXME: Add test two optional arguments, only specify 2nd one
    // struct A: ParsableMacro {
    //   @Argument(label: "foo")
    //   var bar: Int?
    //   @Argument(label: "baz")
    //   var baz: Int?
    // }
    // test that @A(baz: 1) works
  }

  func test_oneArgumentArray_parse() {
    struct A: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var bar: [Int]

      mutating func update(
        label: String,
        from expression: ExprSyntax,
        in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
      ) throws {
        switch label {
        case "foo":
          try self._bar.update(from: expression, in: context)
        default:
          fatalError()
        }
      }
    }

    // Good...
    assertMacroExpansion(
      """
      @A(foo: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A(foo: 1, 2, 3, 4) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    // Bad...
    // FIXME: should error
    assertMacroExpansion(
      """
      @A struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedMissingArgument(label: "foo").message,
          line: 1,
          column: 1,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "@A ")
      ],
      macros: ["A": A.self])

    // FIXME: should error
    assertMacroExpansion(
      """
      @A() struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedMissingArgument(label: "foo").message,
          line: 1,
          column: 1,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "@A() ")
      ],
      macros: ["A": A.self])

    // FIXME: should error
    assertMacroExpansion(
      """
      @A(bar: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedArgumentLabel(expected: "foo", actual: "bar").message,
          line: 1,
          column: 4,
          highlight: "bar: 1")
      ],
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A(foo: 1, baz: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "baz").message,
          line: 1,
          column: 12,
          highlight: "baz: 1")
      ],
      macros: ["A": A.self])
  }

  func test_complex1_parse() {
    struct A: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var foo: Int

      @Argument(label: "bar")
      var bar: Int?

      mutating func update(
        label: String,
        from expression: ExprSyntax,
        in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
      ) throws {
        switch label {
        case "foo":
          try self._foo.update(from: expression, in: context)
        case "bar":
          try self._bar.update(from: expression, in: context)
        default:
          fatalError()
        }
      }
    }

    // Good...
    assertMacroExpansion(
      """
      @A(foo: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A(foo: 1, bar: 2) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    // Bad...
    assertMacroExpansion(
      """
      @A(bar: 2) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedArgumentLabel(expected: "foo", actual: "bar").message,
          line: 1,
          column: 4,
          highlight: "bar: 2")
      ],
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A(foo: 1, baz: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedArgumentLabel(expected: "bar", actual: "baz").message,
          line: 1,
          column: 12,
          highlight: "baz: 1")
      ],
      macros: ["A": A.self])
  }
}
