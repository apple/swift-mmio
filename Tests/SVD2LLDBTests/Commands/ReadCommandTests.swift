//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import MMIOUtilities
import XCTest

@testable import SVD2LLDB

final class ReadCommandTests: XCTestCase {
  func test_argumentParsing() {
    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["--help"],
      success: true,
      debugger: "",
      result: """
        OVERVIEW: Read the value of registers

        USAGE: svd read <key-path> ... [--force]

        ARGUMENTS:
          <key-path>              Key-path to a peripheral, cluster, register, or field.

        OPTIONS:
          --force                 Always read ignoring side-effects.
          -h, --help              Show help information.

        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: [],
      success: false,
      debugger: "",
      result: """
        usage: svd read <key-path> ... [--force]
        error: Missing expected argument '<key-path> ...'
        """)
  }

  func test_badKeyPath() {
    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: [""],
      success: false,
      debugger: "",
      result: """
        error: Invalid key path “”.
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["."],
      success: false,
      debugger: "",
      result: """
        error: Invalid key path “.”.
        """)
  }

  func test_unknownItem() {
    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["ABC"],
      success: false,
      debugger: "",
      result: """
        error: Unknown item “ABC”.
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["ABC", "DEF"],
      success: false,
      debugger: "",
      // FIXME: order is backwards, see ReadCommand.render
      result: """
        error: Unknown item “DEF”.
        error: Unknown item “ABC”.
        """)
  }

  func test_read_single() {
    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["TestPeripheral.TestRegister0"],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1000] -> 0x7a7e_cbd9
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0x7a7e_cbd9
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["TestPeripheral.TestRegister1"],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1004] -> 0x7a7e
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister1: 0x7a7e
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["TestPeripheral.TestRegister2"],
      success: true,
      debugger: "",
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister2: <skipped>
        warning: Skipped registers with side-effects. Use “--force” to read these registers.
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["TestPeripheral.TestRegister2", "--force"],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1008] -> 0x7a7e_cbd9
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister2: 0x7a7e_cbd9
        """)
  }

  func test_read_multiple() {
    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: [
        "TestPeripheral.TestRegister0",
        "TestPeripheral.TestRegister1",
      ],
      success: true,
      // FIXME: order is backwards
      debugger: """
        m[0x0000_0000_0000_1004] -> 0x7a7e
        m[0x0000_0000_0000_1000] -> 0xae64_6aa8
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0xae64_6aa8
            TestRegister1: 0x7a7e
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["TestPeripheral"],
      success: true,
      // FIXME: order is backwards
      debugger: """
        m[0x0000_0000_0000_1012] -> 0x7a7e_cbd9
        m[0x0000_0000_0000_1004] -> 0xae64
        m[0x0000_0000_0000_1000] -> 0x6204_b303
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0x6204_b303
            TestRegister1: 0xae64
            TestRegister2: <skipped>
            TestRegister3: 0x7a7e_cbd9
        warning: Skipped registers with side-effects. Use “--force” to read these registers.
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["TestPeripheral", "--force"],
      success: true,
      // FIXME: order is backwards
      debugger: """
        m[0x0000_0000_0000_1012] -> 0x7a7e_cbd9
        m[0x0000_0000_0000_1008] -> 0xae64_6aa8
        m[0x0000_0000_0000_1004] -> 0x6204
        m[0x0000_0000_0000_1000] -> 0x49fc_e611
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0x49fc_e611
            TestRegister1: 0x6204
            TestRegister2: 0xae64_6aa8
            TestRegister3: 0x7a7e_cbd9
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: [
        "TestPeripheral",
        "TestPeripheral.TestRegister0",
        "--force",
      ],
      success: true,
      // FIXME: order is backwards
      debugger: """
        m[0x0000_0000_0000_1012] -> 0x7a7e_cbd9
        m[0x0000_0000_0000_1008] -> 0xae64_6aa8
        m[0x0000_0000_0000_1004] -> 0x6204
        m[0x0000_0000_0000_1000] -> 0x49fc_e611
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0x49fc_e611
            TestRegister1: 0x6204
            TestRegister2: 0xae64_6aa8
            TestRegister3: 0x7a7e_cbd9
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: [
        "TestPeripheral",
        "TestPeripheral.TestRegister0.Field0",
        "--force",
      ],
      success: true,
      // FIXME: order is backwards
      debugger: """
        m[0x0000_0000_0000_1012] -> 0x7a7e_cbd9
        m[0x0000_0000_0000_1008] -> 0xae64_6aa8
        m[0x0000_0000_0000_1004] -> 0x6204
        m[0x0000_0000_0000_1000] -> 0x49fc_e611
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0x49fc_e611
              Field0:      0x8
            TestRegister1: 0x6204
            TestRegister2: 0xae64_6aa8
            TestRegister3: 0x7a7e_cbd9
        """)
  }

  func test_read_field() {
    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: ["TestPeripheral.TestRegister0.Field0"],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1000] -> 0x7a7e_cbd9
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0x7a7e_cbd9
              Field0:      0xc
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: [
        "TestPeripheral.TestRegister0.Field0",
        "TestPeripheral.TestRegister0",
      ],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1000] -> 0x7a7e_cbd9
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0x7a7e_cbd9
              Field0:      0xc
        """)

    XCTAssertCommand(
      command: ReadCommand.self,
      arguments: [
        "TestPeripheral.TestRegister0.Field0",
        "TestPeripheral.TestRegister0.Field1",
      ],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1000] -> 0x7a7e_cbd9
        """,
      result: """
        TestDevice:
          TestPeripheral:
            TestRegister0: 0x7a7e_cbd9
              Field0:      0xc
              Field1:      0x1
        """)
  }
}
