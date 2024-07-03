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
  subscript(bit bit: Int) -> Bool {
    @inlinable @inline(__always) get {
      (self >> bit) & 0b1 != 0
    }

    @inlinable @inline(__always) set {
      self &= ~(0b1 << bit)
      self |= ((newValue ? 1 : 0) & 0b1) << bit
    }
  }

  /// Note this variant of subscript bits allows for silent truncation
  @inlinable @inline(__always)
  subscript(bits bitRange: Range<Int>) -> Self {
    @inlinable @inline(__always) get {
      let bitWidth = bitRange.upperBound - bitRange.lowerBound
      let bitMask: Self = 1 << bitWidth &- 1
      return (self >> bitRange.lowerBound) & bitMask
    }

    @inlinable @inline(__always) set {
      let bitWidth = bitRange.upperBound - bitRange.lowerBound
      let bitMask: Self = 1 << bitWidth &- 1
      self &= ~(bitMask << bitRange.lowerBound)
      self |= (newValue & bitMask) << bitRange.lowerBound
    }
  }
}
