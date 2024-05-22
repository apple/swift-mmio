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

final class WriteCommandTests: XCTestCase {
  func test_argumentParsing() {
    XCTAssertCommand(
      command: WriteCommand.self,
      arguments: ["--help"],
      success: true,
      debugger: "",
      result: """
        OVERVIEW: Write a new value to a register.

        USAGE: svd write <key-path> <value> [--force]

        ARGUMENTS:
          <key-path>              Key-path to a register or field.
          <value>                 Value to write.

        OPTIONS:
          --force                 Always write or modify ignoring side-effects.
          -h, --help              Show help information.

        """)
  }

  func test_badKeyPath() {
    XCTAssertCommand(
      command: WriteCommand.self,
      // FIXME: remove "--force"
      arguments: ["", "0", "--force"],
      success: false,
      debugger: "",
      result: """
        usage: svd write <key-path> <value> [--force]
        error: Invalid key path “”.
        """)

    XCTAssertCommand(
      command: WriteCommand.self,
      // FIXME: remove "--force"
      arguments: [".", "0", "--force"],
      success: false,
      debugger: "",
      result: """
        usage: svd write <key-path> <value> [--force]
        error: Invalid key path “.”.
        """)
  }

  func test_invalidKeyPath() {
    XCTAssertCommand(
      command: WriteCommand.self,
      // FIXME: remove "--force"
      arguments: ["TestPeripheral", "0", "--force"],
      success: false,
      debugger: "",
      result: """
        error: Invalid register key path “TestPeripheral”.
        """)

    XCTAssertCommand(
      command: WriteCommand.self,
      // FIXME: remove "--force"
      arguments: ["TestPeripheral.TestRegister0.Field0", "0", "--force"],
      success: false,
      debugger: "",
      result: """
        error: Invalid register key path “TestPeripheral.TestRegister0.Field0”.
        """)
  }

  func test_unknownItem() {
    XCTAssertCommand(
      command: WriteCommand.self,
      arguments: ["ABC", "0", "--force"],
      success: false,
      debugger: "",
      result: """
        error: Unknown item “ABC”.
        """)
  }

  func test_write_register() {
    XCTAssertCommand(
      command: WriteCommand.self,
      arguments: ["TestPeripheral.TestRegister0", "19088743", "--force"],
      success: true,
      debugger: """
        m[0x0000_0000_0000_1000] <- 0x0123_4567
        """,
      result: """
        Wrote: 0x0123_4567
        """)

    XCTAssertCommand(
      command: WriteCommand.self,
      arguments: ["TestPeripheral.TestRegister0", "0x1_0123_4567", "--force"],
      success: false,
      debugger: "",
      result: """
        error: Invalid value “0x1_0123_4567“ larger than register size “32“ bits.
        """)
  }

  func test_write_field() {
    // TODO: implement and test
  }
}
