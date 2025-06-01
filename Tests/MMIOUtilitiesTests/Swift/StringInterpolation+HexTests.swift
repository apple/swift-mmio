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

struct StringInterpolationHexTests {
  @Test func appendInterpolation_hexNibble() {
    #expect("\(hexNibble: 0x0)" == "0")
    #expect("\(hexNibble: 0x1)" == "1")
    #expect("\(hexNibble: 0x2)" == "2")
    #expect("\(hexNibble: 0x3)" == "3")
    #expect("\(hexNibble: 0x4)" == "4")
    #expect("\(hexNibble: 0x5)" == "5")
    #expect("\(hexNibble: 0x6)" == "6")
    #expect("\(hexNibble: 0x7)" == "7")
    #expect("\(hexNibble: 0x8)" == "8")
    #expect("\(hexNibble: 0x9)" == "9")
    #expect("\(hexNibble: 0xa)" == "a")
    #expect("\(hexNibble: 0xb)" == "b")
    #expect("\(hexNibble: 0xc)" == "c")
    #expect("\(hexNibble: 0xd)" == "d")
    #expect("\(hexNibble: 0xe)" == "e")
    #expect("\(hexNibble: 0xf)" == "f")
  }

  @Test func appendInterpolation_hex() {
    // Int8
    #expect("\(hex: Int8.min)" == "0x80")
    #expect("\(hex: Int8(-1))" == "0xff")
    #expect("\(hex: Int8(0))" == "0x00")
    #expect("\(hex: Int8(1))" == "0x01")
    #expect("\(hex: Int8.max)" == "0x7f")

    // Int16
    #expect("\(hex: Int16.min)" == "0x8000")
    #expect("\(hex: Int16(-1))" == "0xffff")
    #expect("\(hex: Int16(0))" == "0x0000")
    #expect("\(hex: Int16(1))" == "0x0001")
    #expect("\(hex: Int16.max)" == "0x7fff")

    // Int32
    #expect("\(hex: Int32.min)" == "0x8000_0000")
    #expect("\(hex: Int32(-1))" == "0xffff_ffff")
    #expect("\(hex: Int32(0))" == "0x0000_0000")
    #expect("\(hex: Int32(1))" == "0x0000_0001")
    #expect("\(hex: Int32.max)" == "0x7fff_ffff")

    // Int64
    #expect("\(hex: Int64.min)" == "0x8000_0000_0000_0000")
    #expect("\(hex: Int64(-1))" == "0xffff_ffff_ffff_ffff")
    #expect("\(hex: Int64(0))" == "0x0000_0000_0000_0000")
    #expect("\(hex: Int64(1))" == "0x0000_0000_0000_0001")
    #expect("\(hex: Int64.max)" == "0x7fff_ffff_ffff_ffff")

    // UInt8
    #expect("\(hex: UInt8.min)" == "0x00")
    #expect("\(hex: UInt8(1))" == "0x01")
    #expect("\(hex: UInt8.max)" == "0xff")

    // UInt16
    #expect("\(hex: UInt16.min)" == "0x0000")
    #expect("\(hex: UInt16(1))" == "0x0001")
    #expect("\(hex: UInt16.max)" == "0xffff")

    // UInt32
    #expect("\(hex: UInt32.min)" == "0x0000_0000")
    #expect("\(hex: UInt32(1))" == "0x0000_0001")
    #expect("\(hex: UInt32.max)" == "0xffff_ffff")

    // UInt64
    #expect("\(hex: UInt64.min)" == "0x0000_0000_0000_0000")
    #expect("\(hex: UInt64(1))" == "0x0000_0000_0000_0001")
    #expect("\(hex: UInt64.max)" == "0xffff_ffff_ffff_ffff")
  }

  @Test func appendInterpolation_hex_bits() {
    #expect("\(hex: Int8(-1), bits: 1)" == "0x1")
    #expect("\(hex: Int8(-1), bits: 2)" == "0x3")
    #expect("\(hex: Int8(-1), bits: 3)" == "0x7")
    #expect("\(hex: Int8(-1), bits: 4)" == "0xf")
    #expect("\(hex: Int8(-1), bits: 5)" == "0x1f")
    #expect("\(hex: Int8(-1), bits: 6)" == "0x3f")
    #expect("\(hex: Int8(-1), bits: 7)" == "0x7f")
    #expect("\(hex: Int8(-1), bits: 8)" == "0xff")

    // Int8
    #expect("\(hex: Int8.min, bits: 8)" == "0x80")
    #expect("\(hex: Int8(-1), bits: 8)" == "0xff")
    #expect("\(hex: Int8(0), bits: 8)" == "0x00")
    #expect("\(hex: Int8(1), bits: 8)" == "0x01")
    #expect("\(hex: Int8.max, bits: 8)" == "0x7f")

    // Int16
    #expect("\(hex: Int16.min, bits: 8)" == "0x00")
    #expect("\(hex: Int16(-1), bits: 8)" == "0xff")
    #expect("\(hex: Int16(0), bits: 8)" == "0x00")
    #expect("\(hex: Int16(1), bits: 8)" == "0x01")
    #expect("\(hex: Int16.max, bits: 8)" == "0xff")

    // Int32
    #expect("\(hex: Int32.min, bits: 8)" == "0x00")
    #expect("\(hex: Int32(-1), bits: 8)" == "0xff")
    #expect("\(hex: Int32(0), bits: 8)" == "0x00")
    #expect("\(hex: Int32(1), bits: 8)" == "0x01")
    #expect("\(hex: Int32.max, bits: 8)" == "0xff")

    // Int64
    #expect("\(hex: Int64.min, bits: 8)" == "0x00")
    #expect("\(hex: Int64(-1), bits: 8)" == "0xff")
    #expect("\(hex: Int64(0), bits: 8)" == "0x00")
    #expect("\(hex: Int64(1), bits: 8)" == "0x01")
    #expect("\(hex: Int64.max, bits: 8)" == "0xff")

    // UInt8
    #expect("\(hex: UInt8.min, bits: 8)" == "0x00")
    #expect("\(hex: UInt8(1), bits: 8)" == "0x01")
    #expect("\(hex: UInt8.max, bits: 8)" == "0xff")

    // UInt16
    #expect("\(hex: UInt16.min, bits: 8)" == "0x00")
    #expect("\(hex: UInt16(1), bits: 8)" == "0x01")
    #expect("\(hex: UInt16.max, bits: 8)" == "0xff")

    // UInt32
    #expect("\(hex: UInt32.min, bits: 8)" == "0x00")
    #expect("\(hex: UInt32(1), bits: 8)" == "0x01")
    #expect("\(hex: UInt32.max, bits: 8)" == "0xff")

    // UInt64
    #expect("\(hex: UInt64.min, bits: 8)" == "0x00")
    #expect("\(hex: UInt64(1), bits: 8)" == "0x01")
    #expect("\(hex: UInt64.max, bits: 8)" == "0xff")
  }
}
