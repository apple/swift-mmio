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

@testable import SVD2LLDB

final class DecodeCommandTests: XCTestCase {
  func test_argumentParsing() {
    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["--help"],
      success: true,
      debugger: "",
      result: """
        OVERVIEW: Decode a register value into fields.

        USAGE: svd decode <key-path> [<value>] [--binary] [--read] [--force] [--visual]

        ARGUMENTS:
          <key-path>              Key-path to a register.
          <value>                 Existing value to decode.

        OPTIONS:
          --binary                Print table values in binary instead of hexadecimal.
          --read                  Read the value from the device instead of an existing
                                  value.
          --force                 Always read ignoring side-effects.
          --visual                Include a visual diagram of the fields.
          -h, --help              Show help information.

        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: [],
      success: false,
      debugger: "",
      result: """
        usage: svd decode <key-path> [<value>] [--binary] [--read] [--force] [--visual]
        error: Missing expected argument '<key-path>'
        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["a", "b", "c"],
      success: false,
      debugger: "",
      result: """
        usage: svd decode <key-path> [<value>] [--binary] [--read] [--force] [--visual]
        error: Unexpected argument 'c'
        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister0"],
      success: false,
      debugger: "",
      result: """
        usage: svd decode <key-path> [<value>] [--binary] [--read] [--force] [--visual]
        error: Must either supply a “<value>“ or use the “--read“ flag.
        """)
  }

  func test_badKeyPath() {
    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: [""],
      success: false,
      debugger: "",
      result: """
        usage: svd decode <key-path> [<value>] [--binary] [--read] [--force] [--visual]
        error: Invalid key path “”.
        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["."],
      success: false,
      debugger: "",
      result: """
        usage: svd decode <key-path> [<value>] [--binary] [--read] [--force] [--visual]
        error: Invalid key path “.”.
        """)
  }

  func test_invalidKeyPath() {
    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral"],
      success: false,
      debugger: "",
      result: """
        error: Invalid register key path “TestPeripheral”.
        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister0.Field0"],
      success: false,
      debugger: "",
      result: """
        error: Invalid register key path “TestPeripheral.TestRegister0.Field0”.
        """)
  }

  func test_unknownItem() {
    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["ABC"],
      success: false,
      debugger: "",
      result: """
        error: Unknown item “ABC”.
        """)
  }

  func test_decodeExistingValue() {
    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister0", "0x0123_4567"],
      success: true,
      debugger: "",
      result: """
        TestPeripheral.TestRegister0: 0x0123_4567

        [7:7] Field1 0x0
        [4:1] Field0 0x3
        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister0", "0x1_0123_4567"],
      success: false,
      debugger: "",
      result: """
        error: Invalid value “0x1_0123_4567“ larger than register size “32“ bits.
        """)
  }

  func test_decodeReadValue() {
    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister0", "--read"],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1000] -> 0x7a7e_cbd9
        """,
      result: """
        TestPeripheral.TestRegister0: 0x7a7e_cbd9

        [7:7] Field1 0x1
        [4:1] Field0 0xc
        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister1", "--read"],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1004] -> 0x7a7e
        """,
      result: """
        TestPeripheral.TestRegister1: 0x7a7e

        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister2", "--read"],
      success: false,
      debugger: "",
      result: """
        error: Skipped register with side-effect. Use “--force” to read this register.
        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister2", "--read", "--force"],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1008] -> 0x7a7e_cbd9
        """,
      result: """
        TestPeripheral.TestRegister2: 0x7a7e_cbd9

        """)
  }

  func test_decodeFormat() {
    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister0", "0x0123_4567"],
      success: true,
      debugger: "",
      result: """
        TestPeripheral.TestRegister0: 0x0123_4567

        [7:7] Field1 0x0
        [4:1] Field0 0x3
        """)

    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister0", "0x0123_4567", "--binary"],
      success: true,
      debugger: "",
      result: """
        TestPeripheral.TestRegister0: 0x0123_4567

        [7:7] Field1 0b0
        [4:1] Field0 0b0011
        """)
  }

  func test_decodeVisual() {
    XCTAssertCommand(
      command: DecodeCommand.self,
      arguments: ["TestPeripheral.TestRegister3", "0x0123_4567", "--visual"],
      success: true,
      debugger: "",
      result: """
        TestPeripheral.TestRegister3: 0x0123_4567

                              ╭╴CNTSRC  ╭╴RST
          ╭╴S   ╭╴RELOAD╭╴CAPEDGE  ╭╴MODE
          ┴     ┴─      ┴─    ┴─── ┴──  ┴
        0b00000001001000110100010101100111
              ┬─    ┬─    ┬───    ┬   ┬─ ┬
              ╰╴IDR ╰╴TRGEXT      ╰╴PSC  ╰╴EN
                          ╰╴CAPSRC    ╰╴CNT

        [31:31] S       0x0 (STOP)
        [27:26] IDR     0x0 (KEEP)
        [25:24] RELOAD  0x1 (RELOAD1)
        [21:20] TRGEXT  0x2 (DMA2)
        [17:16] CAPEDGE 0x3
        [15:12] CAPSRC  0x4 (GPIOA_3)
        [11:8]  CNTSRC  0x5 (CAP_SRC_div32)
        [7:7]   PSC     0x0 (Disabled)
        [6:4]   MODE    0x6
        [3:2]   CNT     0x1 (Count_DOWN)
        [1:1]   RST     0x1 (Reset_Timer)
        [0:0]   EN      0x1 (Enable)
        """)
  }
}
