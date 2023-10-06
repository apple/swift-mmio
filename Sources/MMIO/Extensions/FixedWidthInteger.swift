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

extension FixedWidthInteger {
  public subscript<Other: FixedWidthInteger>(
    bits range: Range<Int>, as type: Other.Type = Other.self
  ) -> Other {
    @inline(__always) get {
      precondition(range.lowerBound >= 0)
      precondition(range.upperBound <= Self.bitWidth)
      let width = range.upperBound - range.lowerBound
      precondition(
        width <= Other.bitWidth,
        "\(Other.self) cannot accommodate \(width) bits.")
      let mask: Self = 1 << width &- 1
      return Other(truncatingIfNeeded: self >> range.lowerBound & mask)
    }

    @inline(__always) set {
      precondition(range.lowerBound >= 0)
      precondition(range.upperBound <= Self.bitWidth)
      let width = range.upperBound - range.lowerBound
      precondition(
        width <= Other.bitWidth,
        "\(Other.self) cannot provide \(width) bits.")
      let mask: Self = 1 << width &- 1
      self &= ~(mask << range.lowerBound)
      self |= (Self(truncatingIfNeeded: newValue) & mask) << range.lowerBound
    }
  }
}
