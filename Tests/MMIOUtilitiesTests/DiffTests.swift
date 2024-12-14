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

struct DiffTests {
  @Test func diffFormat() {
    #expect(
      diff(
        expected: """
          m[0x0000_0000_0000_0010] <- 0xa5
          m[0x0000_0000_0000_0020] -> 0x5a
          """,
        actual: """
          m[0x0000_0000_0000_0020] -> 0x5a
          m[0x0000_0000_0000_0030] -> 0xa6
          """,
        noun: "trace") ==
      """
      Actual trace (+) differed from expected trace (-):
      -m[0x0000_0000_0000_0010] <- 0xa5
       m[0x0000_0000_0000_0020] -> 0x5a
      +m[0x0000_0000_0000_0030] -> 0xa6
      """)
  }
}
