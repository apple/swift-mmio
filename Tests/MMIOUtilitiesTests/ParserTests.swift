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
import XCTest

// swift-format-ignore: AlwaysUseLowerCamelCase
func XCTAssertParse<Output>(
  _ parser: Parser<Substring, Output>,
  _ input: String,
  _ expected: Output,
  file: StaticString = #file,
  line: UInt = #line
) where Output: Equatable {
  var input = input[...]
  let parsed = parser.run(&input)
  guard let parsed = parsed else {
    XCTFail("Failed to parse input", file: file, line: line)
    return
  }
  guard parsed == expected else {
    XCTFail(
      """
      Parsed value '\(parsed)' does not match expected value '\(expected)'
      """,
      file: file,
      line: line)
    return
  }
  guard input.isEmpty else {
    XCTFail(
      """
      Failed to fully consume input, remaining: '\(input)'
      """,
      file: file,
      line: line)
    return
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
func XCTAssertNoParse<Output>(
  _ parser: Parser<Substring, Output>,
  _ input: String,
  file: StaticString = #file,
  line: UInt = #line
) where Output: Equatable {
  var input = input[...]
  let original = input
  let parsed = parser.run(&input)
  guard parsed == nil else {
    XCTFail("Unexpected parsed input", file: file, line: line)
    return
  }
  guard input == original else {
    XCTFail(
      """
      Unexpected modified input after failed parsing '\(input)'
      """,
      file: file,
      line: line)
    return
  }
}

final class ParserTests: XCTestCase {
  func test_swiftIntegerParsing() {
    XCTAssertParse(Parser.swiftInteger(Int.self), "0b0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "0o0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "0x0", 0)

    XCTAssertParse(Parser.swiftInteger(Int.self), "-0b0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-0o0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-0x0", 0)

    XCTAssertParse(Parser.swiftInteger(Int.self), "+0b0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+0o0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+0", 0)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+0x0", 0)

    XCTAssertParse(Parser.swiftInteger(Int.self), "0b1", 1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "0o1", 1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "1", 1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "0x1", 1)

    XCTAssertParse(Parser.swiftInteger(Int.self), "-0b1", -1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-0o1", -1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-1", -1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-0x1", -1)

    XCTAssertParse(Parser.swiftInteger(Int.self), "+0b1", 1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+0o1", 1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+1", 1)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+0x1", 1)

    XCTAssertParse(Parser.swiftInteger(Int.self), "0b1_0__1___0", 10)
    XCTAssertParse(Parser.swiftInteger(Int.self), "0o1_0_23456___7", 2_177_399)
    XCTAssertParse(Parser.swiftInteger(Int.self), "01_0_2345678___9", 1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    XCTAssertParse(Parser.swiftInteger(Int.self), "0x1_0_23456789abcde___f", 1_162_849_439_785_405_935)
    #endif

    XCTAssertParse(Parser.swiftInteger(Int.self), "-0b1_0__1___0", -10)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-0o1_0_23456___7", -2_177_399)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-01_0_2345678___9", -1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    XCTAssertParse(Parser.swiftInteger(Int.self), "-0x1_0_23456789abcde___f", -1_162_849_439_785_405_935)
    #endif

    XCTAssertParse(Parser.swiftInteger(Int.self), "+0b1_0__1___0", 10)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+0o1_0_23456___7", 2_177_399)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+01_0_2345678___9", 1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    XCTAssertParse(Parser.swiftInteger(Int.self), "+0x1_0_23456789abcde___f", 1_162_849_439_785_405_935)
    #endif

    XCTAssertNoParse(Parser.swiftInteger(Int.self), "0b_0")
    XCTAssertNoParse(Parser.swiftInteger(Int.self), "0o_0")
    XCTAssertNoParse(Parser.swiftInteger(Int.self), "_0")
    XCTAssertNoParse(Parser.swiftInteger(Int.self), "0x_0")

    XCTAssertNoParse(Parser.swiftInteger(Int.self), " 0b0")
    XCTAssertNoParse(Parser.swiftInteger(Int.self), " 0o0")
    XCTAssertNoParse(Parser.swiftInteger(Int.self), " 0")
    XCTAssertNoParse(Parser.swiftInteger(Int.self), " 0x0")
  }

  func test_swiftIntegerParsing_boundaryConditions() {
    XCTAssertParse(Parser.swiftInteger(UInt8.self), "0xff", 0xff)
    XCTAssertNoParse(Parser.swiftInteger(UInt8.self), "0x100")
  }
}
