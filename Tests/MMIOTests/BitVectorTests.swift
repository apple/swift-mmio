//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import MMIO
import Testing

struct BitVectorTests {
  @Test func bitWidth() {
    #expect(BitVector<0>.bitWidth == 0)
    #expect(BitVector<3>.bitWidth == 3)
    #expect(BitVector<64>.bitWidth == 64)
  }

  @Test func zero() {
    #expect(BitVector<3>.zero == 0)
    #expect(BitVector<0>.zero == 0)
    #expect(BitVector<3>() == .zero)
  }

  @Test func init_exactly_twosComplement() {
    #expect(BitVector<8>(exactly: 200) == 0b1100_1000)
    #expect(BitVector<8>(exactly: -56) == 0b1100_1000)
    #expect(BitVector<8>(exactly: Int8(-1))! == 0b1111_1111)
    #expect(BitVector<8>(exactly: UInt8(255))! == 0b1111_1111)
    #expect(BitVector<16>(exactly: Int8(-1))! == 0b1111_1111_1111_1111)
    #expect(BitVector<16>(exactly: UInt8(255))! == 0b0000_0000_1111_1111)
    #expect(BitVector<32>(exactly: UInt32.max)! == -1)
    #expect(
      BitVector<32>(exactly: Int32.min)! == BitVector<32>(
        exactly: UInt32(1) << 31)!)
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(BitVector<64>(exactly: UInt64.max)! == -1)
    #expect(
      BitVector<64>(exactly: Int64.min)! == BitVector<64>(
        exactly: UInt64(1) << 63)!)
    #endif
  }

  @Test func init_exactly_integer() {
    #expect(BitVector<4>(exactly: 15) == 0b1111)
    #expect(BitVector<4>(exactly: -8) == 0b1000)
    #expect(BitVector<4>(exactly: 16) == nil)
    #expect(BitVector<4>(exactly: -9) == nil)
    #expect(BitVector<1>(exactly: -1) == 0b1)
    #expect(BitVector<1>(exactly: -2) == nil)
    #expect(BitVector<0>(exactly: 0) == BitVector<0>.zero)
    #expect(BitVector<0>(exactly: 1) == nil)
    #expect(BitVector<0>(exactly: -1) == nil)
    #expect(BitVector<3>(exactly: UInt8(255)) == nil)
  }

  @Test func init_truncatingIfNeeded_integer() {
    #expect(BitVector<4>(truncatingIfNeeded: 0x1F) == 0b1111)
    #expect(BitVector<4>(truncatingIfNeeded: 0x30) == 0b0000)
    #expect(BitVector<4>(truncatingIfNeeded: -9) == 0b0111)
    #expect(BitVector<32>(truncatingIfNeeded: -1) == ~BitVector<32>.zero)
  }

  @Test func init_integerLiteral() {
    let mode: BitVector<4> = 0b1010
    let all: BitVector<4> = -1
    let minimum: BitVector<4> = -8
    #expect(UInt8(zeroExtending: mode) == 0b1010)
    #expect(all == 0b1111)
    #expect(minimum == 0b1000)
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    let wide: BitVector<64> = 0xFFFF_FFFF_FFFF_FFFF
    let lowest: BitVector<64> = -0x8000_0000_0000_0000
    #expect(UInt64(zeroExtending: wide) == .max)
    #expect(Int64(signExtending: lowest) == .min)
    #endif
  }

  @Test func init_truncating_bitVector() {
    let wide: BitVector<8> = 0b1010_0110
    #expect(BitVector<4>(truncating: wide) == 0b0110)
    #expect(BitVector<8>(truncating: wide) == 0b1010_0110)
    #expect(BitVector<0>(truncating: wide) == BitVector<0>.zero)
  }

  @Test func init_zeroExtending_bitVector() {
    let narrow: BitVector<4> = 0b1010
    #expect(BitVector<8>(zeroExtending: narrow) == 0b0000_1010)
    #expect(BitVector<4>(zeroExtending: narrow) == 0b1010)
  }

  @Test func init_signExtending_bitVector() {
    #expect(BitVector<8>(signExtending: BitVector<4>(0b1010)) == 0b1111_1010)
    #expect(BitVector<8>(signExtending: BitVector<4>(0b0101)) == 0b0000_0101)
    #expect(BitVector<32>(signExtending: BitVector<1>(1)) == -1)
    #expect(BitVector<8>(signExtending: BitVector<0>.zero) == 0)
  }

  @Test func integer_init_zeroExtending() {
    let prescaler: BitVector<3> = 0b101
    #expect(UInt8(zeroExtending: prescaler) == 5)
    #expect(Int(zeroExtending: prescaler) == 5)
    #expect(UInt8(zeroExtending: BitVector<8>(0xFF)) == 255)
    #expect(Int16(zeroExtending: BitVector<8>(0xFF)) == 255)
  }

  @Test func integer_init_signExtending() {
    let trim: BitVector<4> = 0b1110
    #expect(Int8(signExtending: trim) == -2)
    #expect(Int(signExtending: trim) == -2)
    #expect(UInt8(bitPattern: Int8(signExtending: trim)) == 0b1111_1110)
    #expect(Int32(signExtending: BitVector<32>(exactly: Int32.min)!) == .min)
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(Int64(signExtending: BitVector<64>(exactly: Int64.min)!) == .min)
    #endif
  }

  @Test func integer_init_truncating() {
    let address: BitVector<12> = 0xABC
    #expect(UInt8(truncating: address) == 0xBC)
    #expect(Int8(truncating: address) == -68)
  }

  @Test func bitwiseOperators() {
    let flags: BitVector<4> = 0b1100
    #expect(~BitVector<4>(0b1010) == 0b0101)
    #expect(~BitVector<4>.zero == 0b1111)
    #expect(flags & 0b1010 == 0b1000)
    #expect(flags | 0b1010 == 0b1110)
    #expect(flags ^ 0b1010 == 0b0110)

    var value = flags
    value &= 0b1010
    #expect(value == 0b1000)
    value |= 0b0001
    #expect(value == 0b1001)
    value ^= 0b1111
    #expect(value == 0b0110)
  }

  @Test func description() {
    #expect(BitVector<4>(0b0101).description == "0b0101")
    #expect(BitVector<8>(-1).description == "0b11111111")
    #expect(BitVector<3>.zero.description == "0b000")
    #expect(BitVector<0>.zero.description == "0b0")
  }

  @Test func storage() {
    #expect(BitVector<3>(storage: UInt8(0b101)) == 0b101)
    #expect(BitVector<3>(0b101).storage(UInt32.self) == 0b101)
  }
}
