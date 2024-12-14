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

func assertParse<Value>(
  expression: ExprSyntax,
  expected: Value,
  sourceLocation: SourceLocation = #_sourceLocationPath
) where Value: ExpressibleByExprSyntax, Value: Equatable {
  do {
    let context = MacroContext.makeSuppressingDiagnostics(Macro0.self)
    let actual = try Value(expression: expression, in: context)
    XCTAssertEqual(expected, actual, file: file, line: line)
  } catch {
    XCTFail("Unexpected error: \(error)", file: file, line: line)
  }
}

func assertParseBitFieldTypeProjection(
  expression: ExprSyntax,
  sourceLocation: SourceLocation = #_sourceLocationPath
) {
  let base = expression.as(MemberAccessExprSyntax.self)!.base!
  assertParse(
    expression: expression,
    expected: BitFieldTypeProjection(expression: base),
    file: file,
    line: line)
}

func assertNoParse<Value>(
  expression: ExprSyntax,
  as _: Value.Type,
  sourceLocation: SourceLocation = #_sourceLocationPath
) where Value: ExpressibleByExprSyntax {
  do {
    let context = MacroContext.makeSuppressingDiagnostics(Macro0.self)
    let actual = try Value(expression: expression, in: context)
    XCTFail("Expected error, but got: \(actual)", file: file, line: line)
  } catch {
    XCTAssert(error is ExpansionError, file: file, line: line)
  }
}

struct ExpressibleByExprSyntaxTests {
  @Test func exprSyntax() throws {
    let expression: ExprSyntax = "Bool.self"
    assertParse(expression: expression, expected: expression)
  }

  @Test func int() throws {
    assertParse(expression: "0b1_1110_0010_0100_0000", expected: 123456)
    assertParse(expression: "0o361_100", expected: 123456)
    assertParse(expression: "123456", expected: 123456)
    assertParse(expression: "0x0001_e240", expected: 123456)

    assertNoParse(expression: "1 + 1", as: Int.self)
    // This could be made to work, but its a slippery slope to becoming an
    // arbitrary expression evaluator, so for now parens are banned.
    assertNoParse(expression: "(1234)", as: Int.self)
  }

  @Test func bitRange() throws {
    // UnboundedRange_
    let unboundedRange = ExprSyntax(
      DeclReferenceExprSyntax(
        baseName: .binaryOperator("...")
      ))!
    assertParse(expression: unboundedRange, expected: "(-∞, +∞)" as BitRange)
    // PartialRangeThrough
    assertParse(expression: "...0", expected: "(-∞, 0]" as BitRange)
    // PartialRangeFrom
    assertParse(expression: "0...", expected: "[0, +∞)" as BitRange)
    // ClosedRange
    assertParse(expression: "0...1", expected: "[0, 1]" as BitRange)
    // PartialRangeUpTo
    assertParse(expression: "..<0", expected: "(-∞, 0)" as BitRange)
    // Range
    assertParse(expression: "0..<1", expected: "[0, 1)" as BitRange)

    assertNoParse(expression: "1...0", as: BitRange.self)
    assertNoParse(expression: "1..<0", as: BitRange.self)
    assertNoParse(expression: "1..<1", as: BitRange.self)
    assertNoParse(expression: "(0)..<1", as: BitRange.self)
    assertNoParse(expression: "0..<(1)", as: BitRange.self)
    assertNoParse(expression: "(0)..<(1)", as: BitRange.self)
  }

  @Test func bitWidth() throws {
    assertParse(expression: "8", expected: BitWidth(value: 8))
    assertParse(expression: "16", expected: BitWidth(value: 16))
    assertParse(expression: "32", expected: BitWidth(value: 32))
    assertParse(expression: "64", expected: BitWidth(value: 64))

    assertNoParse(expression: "7", as: BitWidth.self)
  }

  @Test func bitFieldTypeProjection() throws {
    assertParseBitFieldTypeProjection(expression: "Bool.self")
    assertParseBitFieldTypeProjection(expression: "Swift.Bool.self")
    assertParseBitFieldTypeProjection(expression: "Array<Int>.self")
    assertParseBitFieldTypeProjection(expression: "Swift.Array<Int>.self")

    assertNoParse(expression: "Bool", as: BitFieldTypeProjection.self)
    assertNoParse(expression: "1", as: BitFieldTypeProjection.self)
  }
}
#endif
