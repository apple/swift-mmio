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

protocol MMIOArgumentParsingMacro: MMIOMemberMacro {}
extension MMIOArgumentParsingMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool { false }

  mutating func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] { [] }

  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    fatalError()
  }
}

final class ParsableMacroTests: XCTestCase {
  @Test func noArguments_parse() {
    struct A: MMIOArgumentParsingMacro {}

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
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "_")
            .message,
          line: 1,
          column: 4,
          highlights: ["0"])
      ],
      macros: ["A": A.self])
  }

  @Test func oneArgument_parse() {
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
          message: ErrorDiagnostic<A>.unexpectedMissingArgument(label: "foo")
            .message,
          line: 1,
          column: 1,
          highlights: ["@A"])
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
          message: ErrorDiagnostic<A>.unexpectedMissingArgument(label: "foo")
            .message,
          line: 1,
          column: 1,
          highlights: ["@A()"])
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
          message: ErrorDiagnostic<A>.unexpectedArgumentLabel(
            expected: "foo", actual: "bar"
          ).message,
          line: 1,
          column: 4,
          highlights: ["bar: 1"])
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
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "baz")
            .message,
          line: 1,
          column: 12,
          highlights: ["baz: 1"])
      ],
      macros: ["A": A.self])
  }

  @Test func oneArgumentOptional_parse() {
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
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "bar")
            .message,
          line: 1,
          column: 4,
          highlights: ["bar: 1"])
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
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "baz")
            .message,
          line: 1,
          column: 12,
          highlights: ["baz: 1"])
      ],
      macros: ["A": A.self])
  }

  @Test func twoArgumentOptional_parse() {
    struct A: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var foo: Int?

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
      @A(bar: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    assertMacroExpansion(
      """
      @A(foo: 1, bar: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      macros: ["A": A.self])

    // Bad...
    assertMacroExpansion(
      """
      @A(foo: 1, baz: 1) struct S {}
      """,
      expandedSource: """
        struct S {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "baz")
            .message,
          line: 1,
          column: 12,
          highlights: ["baz: 1"])
      ],
      macros: ["A": A.self])
  }

  @Test func oneArgumentArray_parse() {
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
          message: ErrorDiagnostic<A>.unexpectedMissingArgument(label: "foo")
            .message,
          line: 1,
          column: 1,
          highlights: ["@A"])
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
          message: ErrorDiagnostic<A>.unexpectedMissingArgument(label: "foo")
            .message,
          line: 1,
          column: 1,
          highlights: ["@A()"])
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
          message: ErrorDiagnostic<A>.unexpectedArgumentLabel(
            expected: "foo", actual: "bar"
          ).message,
          line: 1,
          column: 4,
          highlights: ["bar: 1"])
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
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "baz")
            .message,
          line: 1,
          column: 12,
          highlights: ["baz: 1"])
      ],
      macros: ["A": A.self])
  }

  @Test func complex1_parse() {
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
          message: ErrorDiagnostic<A>.unexpectedArgumentLabel(
            expected: "foo", actual: "bar"
          ).message,
          line: 1,
          column: 4,
          highlights: ["bar: 2"])
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
          message: ErrorDiagnostic<A>.unexpectedExtraArgument(label: "baz")
            .message,
          line: 1,
          column: 12,
          highlights: ["baz: 1"])
      ],
      macros: ["A": A.self])
  }

  @Test func many_signatures() {
    struct A: MMIOArgumentParsingMacro {}
    struct B: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var foo: Int
    }
    struct C: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var foo: Int

      @Argument(label: "bar")
      var bar: Int
    }
    struct D: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var foo: Int
    }
    struct E: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var foo: Int?
    }
    struct F: MMIOArgumentParsingMacro {
      @Argument(label: "foo")
      var foo: [Int]
    }

    XCTAssertEqual(A.signature, "@A")
    XCTAssertEqual(B.signature, "@B(foo:)")
    XCTAssertEqual(C.signature, "@C(foo:bar:)")
    XCTAssertEqual(D.signature, "@D(foo:)")
    XCTAssertEqual(E.signature, "@E(foo:)")
    XCTAssertEqual(F.signature, "@F(foo:)")

    XCTAssertEqual("\(A.attributeWithPlaceholders)", "@A")
    XCTAssertEqual("\(B.attributeWithPlaceholders)", "@B(foo: <#Int#>)")
    XCTAssertEqual(
      "\(C.attributeWithPlaceholders)", "@C(foo: <#Int#>, bar: <#Int#>)")
    XCTAssertEqual("\(D.attributeWithPlaceholders)", "@D(foo: <#Int#>)")
    XCTAssertEqual("\(E.attributeWithPlaceholders)", "@E(foo: <#Int#>)")
    XCTAssertEqual("\(F.attributeWithPlaceholders)", "@F(foo: <#Int#>)")
  }
}
#endif
