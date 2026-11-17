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

@testable import MMIO

struct BitFieldTests {
  @Test func bitRangeWithinBounds() {
    // In bounds
    #expect(UInt8.bitRangeWithinBounds(bits: 0..<8))  // full width
    #expect(UInt8.bitRangeWithinBounds(bits: 0..<1))  // prefix
    #expect(UInt8.bitRangeWithinBounds(bits: 7..<8))  // suffix
    #expect(UInt8.bitRangeWithinBounds(bits: 4..<6))  // middle

    #expect(UInt32.bitRangeWithinBounds(bits: 0..<32))  // full width
    #expect(UInt32.bitRangeWithinBounds(bits: 0..<10))  // prefix
    #expect(UInt32.bitRangeWithinBounds(bits: 30..<32))  // suffix
    #expect(UInt32.bitRangeWithinBounds(bits: 13..<23))  // middle

    // Out of bounds
    #expect(!UInt8.bitRangeWithinBounds(bits: -1..<2))  // partial lower
    #expect(!UInt8.bitRangeWithinBounds(bits: -2..<(-1)))  // fully lower
    #expect(!UInt8.bitRangeWithinBounds(bits: 7..<12))  // partial upper
    #expect(!UInt8.bitRangeWithinBounds(bits: 9..<12))  // fully upper
    #expect(!UInt8.bitRangeWithinBounds(bits: -2..<12))  // both side

    #expect(!UInt32.bitRangeWithinBounds(bits: -1..<2))  // partial lower
    #expect(!UInt32.bitRangeWithinBounds(bits: -2..<(-1)))  // fully lower
    #expect(!UInt32.bitRangeWithinBounds(bits: 30..<36))  // partial upper
    #expect(!UInt32.bitRangeWithinBounds(bits: 33..<36))  // fully upper
    #expect(!UInt32.bitRangeWithinBounds(bits: -2..<36))  // both side
  }

  @Test func bitRangeExtract() {
    assertExtract(
      bitRanges: 0..<1,
      from: UInt32(0xff00_ff00),
      equals: 0b0)

    assertExtract(
      bitRanges: 8..<9,
      from: UInt32(0xff00_ff00),
      equals: 0b1)

    assertExtract(
      bitRanges: 8..<16,
      from: UInt32(0xff00_ff00),
      equals: 0xff)

    assertExtract(
      bitRanges: 12..<20,
      from: UInt32(0xff00_ff00),
      equals: 0x0f)

    assertExtract(
      bitRanges: 0..<1, 8..<9,
      from: UInt32(0xff00_ff00),
      equals: 0b10)

    assertExtract(
      bitRanges: 0..<1, 8..<9, 12..<20, 23..<25,
      from: UInt32(0xff00_ff00),
      equals: 0b10_00001111_1_0)

    // Bit range order _matters_.
    assertExtract(
      bitRanges: 8..<9, 0..<1, 23..<25, 12..<20,
      from: UInt32(0xff00_ff00),
      equals: 0b00001111_10_0_1)
  }

  @Test func bitRangeInsert() {
    // Set 0 -> 0
    assertInsert(
      value: 0b0,
      bitRanges: 0..<1,
      into: UInt32(0xff00_ff00),
      equals: 0xff00_ff00)

    // Set 1 -> 0
    assertInsert(
      value: 0b0,
      bitRanges: 8..<9,
      into: UInt32(0xff00_ff00),
      equals: 0xff00_fe00)

    // Set 0 -> 1
    assertInsert(
      value: 0b1,
      bitRanges: 0..<1,
      into: UInt32(0xff00_ff01),
      equals: 0xff00_ff01)

    // Set 1 -> 1
    assertInsert(
      value: 0b1,
      bitRanges: 8..<9,
      into: UInt32(0xff00_ff00),
      equals: 0xff00_ff00)

    assertInsert(
      value: 0b10_00001111_1_0,
      bitRanges: 0..<1, 8..<9, 12..<20, 23..<25,
      into: UInt32(0xfe8f_0e01),
      equals: 0xff00_ff00)

    // Bit range order _matters_.
    assertInsert(
      value: 0b00001111_10_0_1,
      bitRanges: 8..<9, 0..<1, 23..<25, 12..<20,
      into: UInt32(0xfe8f_0e01),
      equals: 0xff00_ff00)
  }
}

// MARK: - Bit field types for the macros

extension BitFieldTests {
  /// Values that cover all bits set, no bits set, and a mix of bits.
  static let storages: [UInt32] = [
    0x0000_0000, 0xffff_ffff, 0xff00_ff00, 0x00ff_00ff, 0xdead_beef,
    0x1234_5678, 0x8000_0001, 0x5555_5555, 0xaaaa_aaaa,
  ]

  func assertMatchesSubscript<Value, Projection, BitRanges>(
    _: _MMIOBitField<Value, UInt32, Projection, BitRanges>.Type,
    bitRanges: [Range<Int>],
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    typealias Field = _MMIOBitField<Value, UInt32, Projection, BitRanges>
    let bitWidth = bitRanges.reduce(0) { $0 + $1.count }
    #expect(Field.bitWidth == bitWidth, sourceLocation: sourceLocation)
    let bitMask: UInt32 = 1 << bitWidth &- 1
    for storage in Self.storages {
      #expect(
        Field.extractBits(from: storage) == storage[bits: bitRanges],
        sourceLocation: sourceLocation)
      for value in Self.storages.map({ $0 & bitMask }) {
        var expected = storage
        expected[bits: bitRanges] = value
        var actual = storage
        Field.insertBits(value, into: &actual)
        #expect(actual == expected, sourceLocation: sourceLocation)
      }
    }
  }

  @Test func oneBitRange() {
    typealias Low = _MMIOBitField<
      BitFieldTests, UInt32, Never,
      _MMIOBitFieldRange<0, 1, _MMIOBitFieldRangeEnd>
    >
    typealias Middle = _MMIOBitField<
      BitFieldTests, UInt32, Never,
      _MMIOBitFieldRange<12, 20, _MMIOBitFieldRangeEnd>
    >
    typealias Full = _MMIOBitField<
      BitFieldTests, UInt32, Never,
      _MMIOBitFieldRange<0, 32, _MMIOBitFieldRangeEnd>
    >
    assertMatchesSubscript(Low.self, bitRanges: [0..<1])
    assertMatchesSubscript(Middle.self, bitRanges: [12..<20])
    assertMatchesSubscript(Full.self, bitRanges: [0..<32])
  }

  @Test func multipleBitRanges() {
    typealias Two = _MMIOBitField<
      BitFieldTests, UInt32, Never,
      _MMIOBitFieldRange<0, 1, _MMIOBitFieldRange<8, 9, _MMIOBitFieldRangeEnd>>
    >
    typealias Four = _MMIOBitField<
      BitFieldTests, UInt32, Never,
      _MMIOBitFieldRange<
        0, 1,
        _MMIOBitFieldRange<
          8, 9,
          _MMIOBitFieldRange<
            12, 20, _MMIOBitFieldRange<23, 25, _MMIOBitFieldRangeEnd>
          >
        >
      >
    >
    // Bit range order _matters_.
    typealias Unordered = _MMIOBitField<
      BitFieldTests, UInt32, Never,
      _MMIOBitFieldRange<
        8, 9,
        _MMIOBitFieldRange<
          0, 1,
          _MMIOBitFieldRange<
            23, 25, _MMIOBitFieldRange<12, 20, _MMIOBitFieldRangeEnd>
          >
        >
      >
    >
    assertMatchesSubscript(Two.self, bitRanges: [0..<1, 8..<9])
    assertMatchesSubscript(
      Four.self, bitRanges: [0..<1, 8..<9, 12..<20, 23..<25])
    assertMatchesSubscript(
      Unordered.self, bitRanges: [8..<9, 0..<1, 23..<25, 12..<20])
  }

  @Test func compatibilityMembers() {
    typealias Mode = _MMIOBitField<
      BitFieldTests, UInt32, Never,
      _MMIOBitFieldRange<8, 12, _MMIOBitFieldRangeEnd>
    >
    #expect(Mode.bitRange == 8..<12)
    #expect(Mode.bitOffset == 8)
    #expect(Mode.bitMask == 0b1111)
    #expect(Mode.bitRanges == [8..<12])
    #expect(Mode.Storage.self == UInt32.self)
    #expect(Mode.Projection.self == Never.self)

    typealias Split = _MMIOBitField<
      BitFieldTests, UInt32, Never,
      _MMIOBitFieldRange<0, 1, _MMIOBitFieldRange<4, 6, _MMIOBitFieldRangeEnd>>
    >
    #expect(Split.bitRanges == [0..<1, 4..<6])
  }
}

// FIXME: Add tests to check crash on out of bounds operation
