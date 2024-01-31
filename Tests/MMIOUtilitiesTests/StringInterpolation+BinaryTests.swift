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

final class StringInterpolationBinaryTests: XCTestCase {
  func test_appendInterpolation_binary() {
    // Int8
    XCTAssertEqual("\(binary: Int8.min)", "0b1000_0000")
    XCTAssertEqual("\(binary: Int8(-1))", "0b1111_1111")
    XCTAssertEqual("\(binary: Int8(0))", "0b0000_0000")
    XCTAssertEqual("\(binary: Int8(1))", "0b0000_0001")
    XCTAssertEqual("\(binary: Int8.max)", "0b0111_1111")

    // Int16
    XCTAssertEqual("\(binary: Int16.min)", "0b1000_0000_0000_0000")
    XCTAssertEqual("\(binary: Int16(-1))", "0b1111_1111_1111_1111")
    XCTAssertEqual("\(binary: Int16(0))", "0b0000_0000_0000_0000")
    XCTAssertEqual("\(binary: Int16(1))", "0b0000_0000_0000_0001")
    XCTAssertEqual("\(binary: Int16.max)", "0b0111_1111_1111_1111")

    // Int32
    XCTAssertEqual("\(binary: Int32.min)", "0b1000_0000_0000_0000_0000_0000_0000_0000")
    XCTAssertEqual("\(binary: Int32(-1))", "0b1111_1111_1111_1111_1111_1111_1111_1111")
    XCTAssertEqual("\(binary: Int32(0))", "0b0000_0000_0000_0000_0000_0000_0000_0000")
    XCTAssertEqual("\(binary: Int32(1))", "0b0000_0000_0000_0000_0000_0000_0000_0001")
    XCTAssertEqual("\(binary: Int32.max)", "0b0111_1111_1111_1111_1111_1111_1111_1111")

    // Int64
    XCTAssertEqual(
      "\(binary: Int64.min)", "0b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000")
    XCTAssertEqual(
      "\(binary: Int64(-1))", "0b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111")
    XCTAssertEqual(
      "\(binary: Int64(0))", "0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000")
    XCTAssertEqual(
      "\(binary: Int64(1))", "0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001")
    XCTAssertEqual(
      "\(binary: Int64.max)", "0b0111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111")

    // UInt8
    XCTAssertEqual("\(binary: UInt8.min)", "0b0000_0000")
    XCTAssertEqual("\(binary: UInt8(1))", "0b0000_0001")
    XCTAssertEqual("\(binary: UInt8.max)", "0b1111_1111")

    // UInt16
    XCTAssertEqual("\(binary: UInt16.min)", "0b0000_0000_0000_0000")
    XCTAssertEqual("\(binary: UInt16(1))", "0b0000_0000_0000_0001")
    XCTAssertEqual("\(binary: UInt16.max)", "0b1111_1111_1111_1111")

    // UInt32
    XCTAssertEqual("\(binary: UInt32.min)", "0b0000_0000_0000_0000_0000_0000_0000_0000")
    XCTAssertEqual("\(binary: UInt32(1))", "0b0000_0000_0000_0000_0000_0000_0000_0001")
    XCTAssertEqual("\(binary: UInt32.max)", "0b1111_1111_1111_1111_1111_1111_1111_1111")

    // UInt64
    XCTAssertEqual(
      "\(binary: UInt64.min)", "0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000")
    XCTAssertEqual(
      "\(binary: UInt64(1))", "0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001")
    XCTAssertEqual(
      "\(binary: UInt64.max)", "0b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111")
  }

  func test_appendInterpolation_binary_bytes() {
    // Int8
    XCTAssertEqual("\(binary: Int8.min, bits: 1)", "0b0")
    XCTAssertEqual("\(binary: Int8(-1), bits: 1)", "0b1")
    XCTAssertEqual("\(binary: Int8(0), bits: 1)", "0b0")
    XCTAssertEqual("\(binary: Int8(1), bits: 1)", "0b1")
    XCTAssertEqual("\(binary: Int8.max, bits: 1)", "0b1")

    XCTAssertEqual("\(binary: Int8.min, bits: 2)", "0b00")
    XCTAssertEqual("\(binary: Int8(-1), bits: 2)", "0b11")
    XCTAssertEqual("\(binary: Int8(0), bits: 2)", "0b00")
    XCTAssertEqual("\(binary: Int8(1), bits: 2)", "0b01")
    XCTAssertEqual("\(binary: Int8.max, bits: 2)", "0b11")

    XCTAssertEqual("\(binary: Int8.min, bits: 3)", "0b000")
    XCTAssertEqual("\(binary: Int8(-1), bits: 3)", "0b111")
    XCTAssertEqual("\(binary: Int8(0), bits: 3)", "0b000")
    XCTAssertEqual("\(binary: Int8(1), bits: 3)", "0b001")
    XCTAssertEqual("\(binary: Int8.max, bits: 3)", "0b111")

    XCTAssertEqual("\(binary: Int8.min, bits: 4)", "0b0000")
    XCTAssertEqual("\(binary: Int8(-1), bits: 4)", "0b1111")
    XCTAssertEqual("\(binary: Int8(0), bits: 4)", "0b0000")
    XCTAssertEqual("\(binary: Int8(1), bits: 4)", "0b0001")
    XCTAssertEqual("\(binary: Int8.max, bits: 4)", "0b1111")

    XCTAssertEqual("\(binary: Int8.min, bits: 5)", "0b0_0000")
    XCTAssertEqual("\(binary: Int8(-1), bits: 5)", "0b1_1111")
    XCTAssertEqual("\(binary: Int8(0), bits: 5)", "0b0_0000")
    XCTAssertEqual("\(binary: Int8(1), bits: 5)", "0b0_0001")
    XCTAssertEqual("\(binary: Int8.max, bits: 5)", "0b1_1111")
  }
}
