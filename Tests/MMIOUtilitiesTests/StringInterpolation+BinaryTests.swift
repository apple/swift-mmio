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
import Testing

struct StringInterpolationBinaryTests {
  @Test func appendInterpolation_binary() {
    // Int8
    #expect("\(binary: Int8.min)" == "0b1000_0000")
    #expect("\(binary: Int8(-1))" == "0b1111_1111")
    #expect("\(binary: Int8(0))" == "0b0000_0000")
    #expect("\(binary: Int8(1))" == "0b0000_0001")
    #expect("\(binary: Int8.max)" == "0b0111_1111")

    // Int16
    #expect("\(binary: Int16.min)" == "0b1000_0000_0000_0000")
    #expect("\(binary: Int16(-1))" == "0b1111_1111_1111_1111")
    #expect("\(binary: Int16(0))" == "0b0000_0000_0000_0000")
    #expect("\(binary: Int16(1))" == "0b0000_0000_0000_0001")
    #expect("\(binary: Int16.max)" == "0b0111_1111_1111_1111")

    // Int32
    #expect("\(binary: Int32.min)" == "0b1000_0000_0000_0000_0000_0000_0000_0000")
    #expect("\(binary: Int32(-1))" == "0b1111_1111_1111_1111_1111_1111_1111_1111")
    #expect("\(binary: Int32(0))" == "0b0000_0000_0000_0000_0000_0000_0000_0000")
    #expect("\(binary: Int32(1))" == "0b0000_0000_0000_0000_0000_0000_0000_0001")
    #expect("\(binary: Int32.max)" == "0b0111_1111_1111_1111_1111_1111_1111_1111")

    // Int64
    #expect("\(binary: Int64.min)" == "0b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000")
    #expect("\(binary: Int64(-1))" == "0b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111")
    #expect("\(binary: Int64(0))" == "0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000")
    #expect("\(binary: Int64(1))" == "0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001")
    #expect("\(binary: Int64.max)" == "0b0111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111")

    // UInt8
    #expect("\(binary: UInt8.min)" == "0b0000_0000")
    #expect("\(binary: UInt8(1))" == "0b0000_0001")
    #expect("\(binary: UInt8.max)" == "0b1111_1111")

    // UInt16
    #expect("\(binary: UInt16.min)" == "0b0000_0000_0000_0000")
    #expect("\(binary: UInt16(1))" == "0b0000_0000_0000_0001")
    #expect("\(binary: UInt16.max)" == "0b1111_1111_1111_1111")

    // UInt32
    #expect("\(binary: UInt32.min)" == "0b0000_0000_0000_0000_0000_0000_0000_0000")
    #expect("\(binary: UInt32(1))" == "0b0000_0000_0000_0000_0000_0000_0000_0001")
    #expect("\(binary: UInt32.max)" == "0b1111_1111_1111_1111_1111_1111_1111_1111")

    // UInt64
    #expect("\(binary: UInt64.min)" == "0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000")
    #expect("\(binary: UInt64(1))" == "0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001")
    #expect("\(binary: UInt64.max)" == "0b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111")
  }

  @Test func appendInterpolation_binary_bytes() {
    // Int8
    #expect("\(binary: Int8.min, bits: 1)" == "0b0")
    #expect("\(binary: Int8(-1), bits: 1)" == "0b1")
    #expect("\(binary: Int8(0), bits: 1)" == "0b0")
    #expect("\(binary: Int8(1), bits: 1)" == "0b1")
    #expect("\(binary: Int8.max, bits: 1)" == "0b1")

    #expect("\(binary: Int8.min, bits: 2)" == "0b00")
    #expect("\(binary: Int8(-1), bits: 2)" == "0b11")
    #expect("\(binary: Int8(0), bits: 2)" == "0b00")
    #expect("\(binary: Int8(1), bits: 2)" == "0b01")
    #expect("\(binary: Int8.max, bits: 2)" == "0b11")

    #expect("\(binary: Int8.min, bits: 3)" == "0b000")
    #expect("\(binary: Int8(-1), bits: 3)" == "0b111")
    #expect("\(binary: Int8(0), bits: 3)" == "0b000")
    #expect("\(binary: Int8(1), bits: 3)" == "0b001")
    #expect("\(binary: Int8.max, bits: 3)" == "0b111")

    #expect("\(binary: Int8.min, bits: 4)" == "0b0000")
    #expect("\(binary: Int8(-1), bits: 4)" == "0b1111")
    #expect("\(binary: Int8(0), bits: 4)" == "0b0000")
    #expect("\(binary: Int8(1), bits: 4)" == "0b0001")
    #expect("\(binary: Int8.max, bits: 4)" == "0b1111")

    #expect("\(binary: Int8.min, bits: 5)" == "0b0_0000")
    #expect("\(binary: Int8(-1), bits: 5)" == "0b1_1111")
    #expect("\(binary: Int8(0), bits: 5)" == "0b0_0000")
    #expect("\(binary: Int8(1), bits: 5)" == "0b0_0001")
    #expect("\(binary: Int8.max, bits: 5)" == "0b1_1111")
  }
}
