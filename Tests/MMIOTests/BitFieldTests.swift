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

import XCTest

@testable import MMIO

extension String.StringInterpolation {
  mutating func appendInterpolation(hexNibble value: UInt8) {
    let ascii: UInt8
    switch value {
    case 0..<10:
      ascii = UInt8(ascii: "0") + value
    case 10..<16:
      ascii = UInt8(ascii: "a") + (value - 10)
    default:
      fatalError()
    }
    let character = Character(UnicodeScalar(ascii))
    self.appendInterpolation(character)
  }

  mutating func appendInterpolation<Value>(
    hex value: Value,
    size: Int? = nil
  ) where Value: FixedWidthInteger {
    precondition((size ?? 0) <= MemoryLayout<Value>.size)
    let size = size ?? MemoryLayout<Value>.size
    let sizeIsEven = size.isMultiple(of: 2)

    // Big endian so we can iterate from high to low byte
    var value = value.bigEndian

    self.appendLiteral("0x")
    for offset in 0..<size {
      if offset != 0, offset.isMultiple(of: 2) == sizeIsEven {
        self.appendLiteral("_")
      }
      let byte = UInt8(truncatingIfNeeded: value)
      let highNibble = byte >> 4
      let lowNibble = byte & 0xf
      self.appendInterpolation(hexNibble: highNibble)
      self.appendInterpolation(hexNibble: lowNibble)
      value = value >> 8
    }
  }
}

func XCTAssertExtract<Storage>(
  bitRanges: Range<Int>...,
  from storage: Storage,
  equals expected: Storage,
  file: StaticString = #filePath,
  line: UInt = #line
) where Storage: FixedWidthInteger {
  let actual = storage[bits: bitRanges]
  XCTAssertEqual(
    actual,
    expected,
    """
    Extracting value \
    from '\(hex: storage)' \
    at bit ranges \(bitRanges
      .map { "\($0.lowerBound)..<\($0.upperBound)" }
      .joined(separator: ", "))] \
    resulted in '\(hex: actual)', \
    but expected '\(hex: expected)'
    """,
    file: file,
    line: line)
}

func XCTAssertInsert<Storage>(
  value: Storage,
  bitRanges: Range<Int>...,
  into storage: Storage,
  equals expected: Storage,
  file: StaticString = #filePath,
  line: UInt = #line
) where Storage: FixedWidthInteger {
  var actual = storage
  actual[bits: bitRanges] = value
  XCTAssertEqual(
    actual,
    expected,
    """
    Inserting '\(hex: value)' \
    into '\(hex: storage)' \
    at bit ranges [\(bitRanges
      .map { "\($0.lowerBound)..<\($0.upperBound)" }
      .joined(separator: ", "))] \
    resulted in '\(hex: actual)', \
    but expected to get '\(hex: expected)'
    """,
    file: file,
    line: line)
}

final class BitFieldTests: XCTestCase {
  func test_bitRangeWithinBounds() {
    // In bounds
    XCTAssertTrue(UInt8.bitRangeWithinBounds(bits: 0..<8))  // full width
    XCTAssertTrue(UInt8.bitRangeWithinBounds(bits: 0..<1))  // prefix
    XCTAssertTrue(UInt8.bitRangeWithinBounds(bits: 7..<8))  // suffix
    XCTAssertTrue(UInt8.bitRangeWithinBounds(bits: 4..<6))  // middle

    XCTAssertTrue(UInt32.bitRangeWithinBounds(bits: 0..<32))  // full width
    XCTAssertTrue(UInt32.bitRangeWithinBounds(bits: 0..<10))  // prefix
    XCTAssertTrue(UInt32.bitRangeWithinBounds(bits: 30..<32))  // suffix
    XCTAssertTrue(UInt32.bitRangeWithinBounds(bits: 13..<23))  // middle

    // Out of bounds
    XCTAssertFalse(UInt8.bitRangeWithinBounds(bits: -1..<2))  // partial lower
    XCTAssertFalse(UInt8.bitRangeWithinBounds(bits: -2..<(-1)))  // fully lower
    XCTAssertFalse(UInt8.bitRangeWithinBounds(bits: 7..<12))  // partial upper
    XCTAssertFalse(UInt8.bitRangeWithinBounds(bits: 9..<12))  // fully upper
    XCTAssertFalse(UInt8.bitRangeWithinBounds(bits: -2..<12))  // both side

    XCTAssertFalse(UInt32.bitRangeWithinBounds(bits: -1..<2))  // partial lower
    XCTAssertFalse(UInt32.bitRangeWithinBounds(bits: -2..<(-1)))  // fully lower
    XCTAssertFalse(UInt32.bitRangeWithinBounds(bits: 30..<36))  // partial upper
    XCTAssertFalse(UInt32.bitRangeWithinBounds(bits: 33..<36))  // fully upper
    XCTAssertFalse(UInt32.bitRangeWithinBounds(bits: -2..<36))  // both side
  }

  func test_bitRangeCoalesced() {
    // Coalesced
    XCTAssertTrue(UInt8.bitRangesCoalesced(bits: [0..<1, 2..<5, 7..<8]))
    XCTAssertTrue(UInt8.bitRangesCoalesced(bits: [2..<3, 0..<1]))  // Not sorted
    // FIXME: this should only be valid if in reverse order 1..<2, 0..<1
    XCTAssertTrue(UInt8.bitRangesCoalesced(bits: [0..<1, 1..<2]))  // Touching
    // v Good. ^ Bad.
    XCTAssertTrue(UInt8.bitRangesCoalesced(bits: [1..<2, 0..<1]))  // Touching

    // Not coalesced
    XCTAssertFalse(UInt8.bitRangesCoalesced(bits: [0..<1, 0..<2]))
  }

  func test_bitRangeExtract() {
    XCTAssertExtract(
      bitRanges: 0..<1,
      from: UInt32(0xff00_ff00),
      equals: 0b0)

    XCTAssertExtract(
      bitRanges: 8..<9,
      from: UInt32(0xff00_ff00),
      equals: 0b1)

    XCTAssertExtract(
      bitRanges: 8..<16,
      from: UInt32(0xff00_ff00),
      equals: 0xff)

    XCTAssertExtract(
      bitRanges: 12..<20,
      from: UInt32(0xff00_ff00),
      equals: 0x0f)

    XCTAssertExtract(
      bitRanges: 0..<1, 8..<9,
      from: UInt32(0xff00_ff00),
      equals: 0b10)

    XCTAssertExtract(
      bitRanges: 0..<1, 8..<9, 12..<20, 23..<25,
      from: UInt32(0xff00_ff00),
      equals: 0b10_00001111_1_0)

    // Bit range order _matters_.
    XCTAssertExtract(
      bitRanges: 8..<9, 0..<1, 23..<25, 12..<20,
      from: UInt32(0xff00_ff00),
      equals: 0b00001111_10_0_1)
  }

  func test_bitRangeInsert() {
    // Set 0 -> 0
    XCTAssertInsert(
      value: 0b0,
      bitRanges: 0..<1,
      into: UInt32(0xff00_ff00),
      equals: 0xff00_ff00)

    // Set 1 -> 0
    XCTAssertInsert(
      value: 0b0,
      bitRanges: 8..<9,
      into: UInt32(0xff00_ff00),
      equals: 0xff00_fe00)

    // Set 0 -> 1
    XCTAssertInsert(
      value: 0b1,
      bitRanges: 0..<1,
      into: UInt32(0xff00_ff01),
      equals: 0xff00_ff01)

    // Set 1 -> 1
    XCTAssertInsert(
      value: 0b1,
      bitRanges: 8..<9,
      into: UInt32(0xff00_ff00),
      equals: 0xff00_ff00)

    XCTAssertInsert(
      value: 0b10_00001111_1_0,
      bitRanges: 0..<1, 8..<9, 12..<20, 23..<25,
      into: UInt32(0xfe8f_0e01),
      equals: 0xff00_ff00)

    // Bit range order _matters_.
    XCTAssertInsert(
      value: 0b00001111_10_0_1,
      bitRanges: 8..<9, 0..<1, 23..<25, 12..<20,
      into: UInt32(0xfe8f_0e01),
      equals: 0xff00_ff00)
  }
}
