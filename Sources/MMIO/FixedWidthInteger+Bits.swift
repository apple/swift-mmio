//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension FixedWidthInteger {
  // This condition should already satisfied by the macro. This method is a
  // soundness check used only in debug mode to catch bugs in the macro.
  @export(implementation) @inline(always)
  static func bitRangeWithinBounds(bits bitRange: Range<Int>) -> Bool {
    bitRange.lowerBound >= 0 && bitRange.upperBound <= Self.bitWidth
  }

  @export(implementation) @inline(always)
  subscript(bits bitRange: Range<Int>) -> Self {
    @export(implementation) @inline(always) get {
      assert(Self.bitRangeWithinBounds(bits: bitRange))
      let bitWidth = bitRange.upperBound - bitRange.lowerBound
      let bitMask: Self = 1 << bitWidth &- 1
      return (self >> bitRange.lowerBound) & bitMask
    }

    @export(implementation) @inline(always) set {
      assert(Self.bitRangeWithinBounds(bits: bitRange))
      let bitWidth = bitRange.upperBound - bitRange.lowerBound
      let bitMask: Self = 1 << bitWidth &- 1
      self &= ~(bitMask << bitRange.lowerBound)
      precondition((newValue & (~bitMask)) == 0)
      self |= (newValue & bitMask) << bitRange.lowerBound
    }
  }
}

extension FixedWidthInteger {
  @export(implementation) @inline(always)
  subscript(bits bitRanges: [Range<Int>]) -> Self {
    @export(implementation) @inline(always) get {
      var currentShift = 0
      var value: Self = 0
      for bitRange in bitRanges {
        assert(Self.bitRangeWithinBounds(bits: bitRange))
        let bitWidth = bitRange.upperBound - bitRange.lowerBound
        let bitMask: Self = 1 << bitWidth &- 1
        let valueSlice = (self >> bitRange.lowerBound) & bitMask
        value |= valueSlice << currentShift
        currentShift += bitWidth
      }
      return value
    }

    @export(implementation) @inline(always) set {
      var fullBitWidth = 0
      for bitRange in bitRanges {
        fullBitWidth += bitRange.upperBound - bitRange.lowerBound
      }
      let fullBitMask: Self = 1 << fullBitWidth &- 1
      precondition((newValue & (~fullBitMask)) == 0)

      var newValue = newValue
      for bitRange in bitRanges {
        assert(Self.bitRangeWithinBounds(bits: bitRange))
        let bitWidth = bitRange.upperBound - bitRange.lowerBound
        let bitMask: Self = 1 << bitWidth &- 1
        self &= ~(bitMask << bitRange.lowerBound)
        self |= (newValue & bitMask) << bitRange.lowerBound
        newValue >>= bitWidth
      }
    }
  }
}
