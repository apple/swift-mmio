//===----------------------------------------------------------------------===//
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

extension ParserTests {
  @Test func parseSwiftInteger() {
    let parser = SwiftIntegerParser<Int>()

    assertParse(parser, "0b0", 0)
    assertParse(parser, "0o0", 0)
    assertParse(parser, "0", 0)
    assertParse(parser, "0x0", 0)

    assertParse(parser, "-0b0", 0)
    assertParse(parser, "-0o0", 0)
    assertParse(parser, "-0", 0)
    assertParse(parser, "-0x0", 0)

    assertParse(parser, "+0b0", 0)
    assertParse(parser, "+0o0", 0)
    assertParse(parser, "+0", 0)
    assertParse(parser, "+0x0", 0)

    assertParse(parser, "0b1", 1)
    assertParse(parser, "0o1", 1)
    assertParse(parser, "1", 1)
    assertParse(parser, "0x1", 1)

    assertParse(parser, "-0b1", -1)
    assertParse(parser, "-0o1", -1)
    assertParse(parser, "-1", -1)
    assertParse(parser, "-0x1", -1)

    assertParse(parser, "+0b1", 1)
    assertParse(parser, "+0o1", 1)
    assertParse(parser, "+1", 1)
    assertParse(parser, "+0x1", 1)

    assertParse(parser, "0b1_0__1___0", 10)
    assertParse(parser, "0o1_0_23456___7", 2_177_399)
    assertParse(
      parser, "01_0_2345678___9", 1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    assertParse(
      parser, "0x1_0_23456789abcde___f",
      1_162_849_439_785_405_935)
    #endif

    assertParse(parser, "-0b1_0__1___0", -10)
    assertParse(
      parser, "-0o1_0_23456___7", -2_177_399)
    assertParse(
      parser, "-01_0_2345678___9", -1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    assertParse(
      parser, "-0x1_0_23456789abcde___f",
      -1_162_849_439_785_405_935)
    #endif

    assertParse(parser, "+0b1_0__1___0", 10)
    assertParse(parser, "+0o1_0_23456___7", 2_177_399)
    assertParse(
      parser, "+01_0_2345678___9", 1_023_456_789)
    #if arch(x86_64) || arch(arm64)
    assertParse(
      parser, "+0x1_0_23456789abcde___f",
      1_162_849_439_785_405_935)
    #endif

    assertNoParse(parser, "0b_0")
    assertNoParse(parser, "0o_0")
    assertNoParse(parser, "_0")
    assertNoParse(parser, "0x_0")

    assertNoParse(parser, " 0b0")
    assertNoParse(parser, " 0o0")
    assertNoParse(parser, " 0")
    assertNoParse(parser, " 0x0")
  }

  @Test func parseSwiftInteger_boundaryConditions() {
    let parser = SwiftIntegerParser<UInt8>()

    assertParse(parser, "0xff", 0xff)
    assertNoParse(parser, "0x100")
  }
}
