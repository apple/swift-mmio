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

import MMIOUtilities
import Testing

func assertParse<Output>(
  _ parser: Parser<Substring, Output>,
  _ input: String,
  _ expected: Output,
  sourceLocation: SourceLocation = #_sourceLocation
) where Output: Equatable {
  var input = input[...]
  let parsed = parser.run(&input)

  do {
    let parsed = try #require(
      parsed,
      "Failed to parse input",
      sourceLocation: sourceLocation)
    try #require(
      parsed == expected,
      "Parsed value '\(parsed)' does not match expected value '\(expected)'",
      sourceLocation: sourceLocation)
    try #require(
      input.isEmpty,
      "Failed to fully consume input, remaining: '\(input)'",
      sourceLocation: sourceLocation)
  } catch { }
}

func assertNoParse<Output>(
  _ parser: Parser<Substring, Output>,
  _ input: String,
  sourceLocation: SourceLocation = #_sourceLocation
) where Output: Equatable {
  var input = input[...]
  let original = input
  let parsed = parser.run(&input)
  #expect(parsed == nil, sourceLocation: sourceLocation)
  #expect(input == original, sourceLocation: sourceLocation)
}

struct ParserTests {
  @Test func swiftIntegerParsing() {
    assertParse(Parser.swiftInteger(Int.self), "0b0", 0)
    assertParse(Parser.swiftInteger(Int.self), "0o0", 0)
    assertParse(Parser.swiftInteger(Int.self), "0", 0)
    assertParse(Parser.swiftInteger(Int.self), "0x0", 0)

    assertParse(Parser.swiftInteger(Int.self), "-0b0", 0)
    assertParse(Parser.swiftInteger(Int.self), "-0o0", 0)
    assertParse(Parser.swiftInteger(Int.self), "-0", 0)
    assertParse(Parser.swiftInteger(Int.self), "-0x0", 0)

    assertParse(Parser.swiftInteger(Int.self), "+0b0", 0)
    assertParse(Parser.swiftInteger(Int.self), "+0o0", 0)
    assertParse(Parser.swiftInteger(Int.self), "+0", 0)
    assertParse(Parser.swiftInteger(Int.self), "+0x0", 0)

    assertParse(Parser.swiftInteger(Int.self), "0b1", 1)
    assertParse(Parser.swiftInteger(Int.self), "0o1", 1)
    assertParse(Parser.swiftInteger(Int.self), "1", 1)
    assertParse(Parser.swiftInteger(Int.self), "0x1", 1)

    assertParse(Parser.swiftInteger(Int.self), "-0b1", -1)
    assertParse(Parser.swiftInteger(Int.self), "-0o1", -1)
    assertParse(Parser.swiftInteger(Int.self), "-1", -1)
    assertParse(Parser.swiftInteger(Int.self), "-0x1", -1)

    assertParse(Parser.swiftInteger(Int.self), "+0b1", 1)
    assertParse(Parser.swiftInteger(Int.self), "+0o1", 1)
    assertParse(Parser.swiftInteger(Int.self), "+1", 1)
    assertParse(Parser.swiftInteger(Int.self), "+0x1", 1)

    assertParse(Parser.swiftInteger(Int.self), "0b1_0__1___0", 10)
    assertParse(Parser.swiftInteger(Int.self), "0o1_0_23456___7", 2_177_399)
    assertParse(
      Parser.swiftInteger(Int.self), "01_0_2345678___9", 1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    assertParse(
      Parser.swiftInteger(Int.self), "0x1_0_23456789abcde___f",
      1_162_849_439_785_405_935)
    #endif

    assertParse(Parser.swiftInteger(Int.self), "-0b1_0__1___0", -10)
    assertParse(
      Parser.swiftInteger(Int.self), "-0o1_0_23456___7", -2_177_399)
    assertParse(
      Parser.swiftInteger(Int.self), "-01_0_2345678___9", -1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    assertParse(
      Parser.swiftInteger(Int.self), "-0x1_0_23456789abcde___f",
      -1_162_849_439_785_405_935)
    #endif

    assertParse(Parser.swiftInteger(Int.self), "+0b1_0__1___0", 10)
    assertParse(Parser.swiftInteger(Int.self), "+0o1_0_23456___7", 2_177_399)
    assertParse(
      Parser.swiftInteger(Int.self), "+01_0_2345678___9", 1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    assertParse(
      Parser.swiftInteger(Int.self), "+0x1_0_23456789abcde___f",
      1_162_849_439_785_405_935)
    #endif

    assertNoParse(Parser.swiftInteger(Int.self), "0b_0")
    assertNoParse(Parser.swiftInteger(Int.self), "0o_0")
    assertNoParse(Parser.swiftInteger(Int.self), "_0")
    assertNoParse(Parser.swiftInteger(Int.self), "0x_0")

    assertNoParse(Parser.swiftInteger(Int.self), " 0b0")
    assertNoParse(Parser.swiftInteger(Int.self), " 0o0")
    assertNoParse(Parser.swiftInteger(Int.self), " 0")
    assertNoParse(Parser.swiftInteger(Int.self), " 0x0")
  }

  @Test func swiftIntegerParsing_boundaryConditions() {
    assertParse(Parser.swiftInteger(UInt8.self), "0xff", 0xff)
    assertNoParse(Parser.swiftInteger(UInt8.self), "0x100")
  }
}
