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

final class InfoCommandTests: XCTestCase {
  func test_argumentParsing() {
    XCTAssertCommand(
      command: InfoCommand.self,
      arguments: ["--help"],
      success: true,
      debugger: "",
      result: """
        OVERVIEW: Retrieve information about hardware items.

        USAGE: svd info <key-path> ...

        ARGUMENTS:
          <key-path>              Key-path to a device, peripheral, cluster, register,
                                  or field.

        OPTIONS:
          -h, --help              Show help information.

        """)

    XCTAssertCommand(
      command: InfoCommand.self,
      arguments: [],
      success: false,
      debugger: "",
      result: """
        usage: svd info <key-path> ...
        error: Missing expected argument '<key-path> ...'
        """)
  }

  func test_info() {
    XCTAssertCommand(
      command: InfoCommand.self,
      arguments: [""],
      success: true,
      debugger: "",
      result: """
        TestDevice:
          Description:           A device to test the svd2lldb lldb plugin.
          Address Bit Alignment: 8
          Single Transfer Width: 32
          Peripherals:           [TestPeripheral]
        """)

    XCTAssertCommand(
      command: InfoCommand.self,
      arguments: ["."],
      success: true,
      debugger: "",
      result: """
        TestDevice:
          Description:           A device to test the svd2lldb lldb plugin.
          Address Bit Alignment: 8
          Single Transfer Width: 32
          Peripherals:           [TestPeripheral]
        """)

    XCTAssertCommand(
      command: InfoCommand.self,
      arguments: ["TestPeripheral"],
      success: true,
      debugger: "",
      result: """
        TestPeripheral:
          Description: A perisperhal with some registers.
          Address:     0x0000_0000_0000_1000
          Registers:   [TestRegister0, TestRegister1, TestRegister2, TestRegister3]
        """)

    XCTAssertCommand(
      command: InfoCommand.self,
      arguments: ["TestPeripheral.TestRegister0"],
      success: true,
      debugger: "",
      result: """
        TestPeripheral.TestRegister0:
          Description: A simple register with fields.
          Address:     0x0000_0000_0000_1000
          Bit Width:   32
          Fields:      [Field0, Field1]
        """)

    XCTAssertCommand(
      command: InfoCommand.self,
      arguments: ["TestPeripheral.TestRegister0.Field0"],
      success: true,
      debugger: "",
      result: """
        TestPeripheral.TestRegister0.Field0:
          Bit Range: [4:1]
        """)

    XCTAssertCommand(
      command: InfoCommand.self,
      arguments: [
        "TestPeripheral.TestRegister2",
        ".",
        "TestPeripheral.TestRegister0.Field0",
        "TestPeripheral.Unknown",
      ],
      success: false,
      debugger: "",
      // FIXME: order lost.
      result: """
        TestDevice:
          Description:           A device to test the svd2lldb lldb plugin.
          Address Bit Alignment: 8
          Single Transfer Width: 32
          Peripherals:           [TestPeripheral]

        TestPeripheral.TestRegister2:
          Address:               0x0000_0000_0000_1008
          Bit Width:             32
          Read Action:           clear

        TestPeripheral.TestRegister0.Field0:
          Bit Range:             [4:1]
        error: Unknown item “TestPeripheral.Unknown”.
        """)
  }
}
