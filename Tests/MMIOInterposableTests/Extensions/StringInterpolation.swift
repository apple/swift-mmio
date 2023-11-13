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
  mutating func appendInterpolation(hexNibble value: UInt8) {
    let ascii: UInt8
    switch value {
    case 0..<10:
      ascii = UInt8(ascii: "0") + value
    case 10..<16:
      ascii = UInt8(ascii: "a") + (value - 10)
    default:
      preconditionFailure("Invalid hexNibble \(value)")
    }
    let character = Character(UnicodeScalar(ascii))
    self.appendInterpolation(character)
  }

  mutating func appendInterpolation<Value>(
    hex value: Value,
    bytes size: Int? = nil
  ) where Value: FixedWidthInteger {
    let valueSize = MemoryLayout<Value>.size
    precondition((size ?? 0) <= valueSize)
    let size = size ?? valueSize
    let sizeIsEven = size.isMultiple(of: 2)

    // Big endian so we can iterate from high to low byte
    var value = value.bigEndian

    let droppedBytes = valueSize - size
    value >>= 8 * droppedBytes

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
      value >>= 8
    }
  }
}
