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

extension FixedWidthInteger {
  @inlinable @inline(__always)
  static func bitRangeWithinBounds(bits bitRange: Range<UInt64>) -> Bool {
    bitRange.lowerBound >= 0 && bitRange.upperBound <= Self.bitWidth
  }

  @inlinable @inline(__always)
  subscript(bits bitRange: Range<UInt64>) -> Self {
    @inlinable @inline(__always) get {
      precondition(Self.bitRangeWithinBounds(bits: bitRange))
      let bitWidth = bitRange.upperBound - bitRange.lowerBound
      let bitMask: Self = 1 << bitWidth &- 1
      return (self >> bitRange.lowerBound) & bitMask
    }

    @inlinable @inline(__always) set {
      precondition(Self.bitRangeWithinBounds(bits: bitRange))
      let bitWidth = bitRange.upperBound - bitRange.lowerBound
      let bitMask: Self = 1 << bitWidth &- 1
      self &= ~(bitMask << bitRange.lowerBound)
      precondition((newValue & (~bitMask)) == 0)
      self |= (newValue & bitMask) << bitRange.lowerBound
    }
  }
}
