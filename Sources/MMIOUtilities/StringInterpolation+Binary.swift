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

extension String.StringInterpolation {
  public mutating func appendInterpolation<Value>(
    binary value: Value,
    bits size: Int? = nil,
    segmented: Bool = true
  ) where Value: FixedWidthInteger {
    let valueSize = MemoryLayout<Value>.size * 8
    precondition((size ?? 0) <= valueSize)
    let size = size ?? valueSize
    let digitsBeforeUnderscore = size % 4

    // Left shift by dropped bits so we can pop the high bit off the value
    // size number of times.
    let droppedBits = valueSize - size
    var value = value << droppedBits
    let mask = Value(1) << (valueSize - 1)

    self.appendLiteral("0b")
    for offset in 0..<size {
      if segmented, offset != 0, (offset - digitsBeforeUnderscore) % 4 == 0 {
        self.appendLiteral("_")
      }
      if (value & mask) == 0 {
        self.appendInterpolation("0")
      } else {
        self.appendInterpolation("1")
      }
      value <<= 1
    }
  }
}
