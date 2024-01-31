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
  public mutating func appendInterpolation(
    hexNibble value: some FixedWidthInteger
  ) {
    let ascii: UInt8
    switch value {
    case 0..<10:
      ascii = UInt8(ascii: "0") + UInt8(value)
    case 10..<16:
      ascii = UInt8(ascii: "a") + UInt8(value - 10)
    default:
      preconditionFailure("Invalid hexadecimal digit \(value)")
    }
    let character = Character(UnicodeScalar(ascii))
    self.appendInterpolation(character)
  }

  public mutating func appendInterpolation<Integer>(
    hex value: Integer
  ) where Integer: FixedWidthInteger {
    self._appendInterpolation(hex: value, bits: nil)
  }

  public mutating func appendInterpolation<Integer>(
    hex value: Integer,
    bits requestedBitWidth: some FixedWidthInteger
  ) where Integer: FixedWidthInteger {
    self._appendInterpolation(hex: value, bits: Int(requestedBitWidth))
  }

  mutating func _appendInterpolation<Integer>(
    hex value: Integer,
    bits requestedBitWidth: Int?
  ) where Integer: FixedWidthInteger {
    let typeBitWidth = MemoryLayout<Integer>.size * 8
    if let requestedBitWidth = requestedBitWidth {
      precondition(requestedBitWidth > 0)
      precondition(requestedBitWidth <= typeBitWidth)
    }
    // Round bitWidth up to the next multiple of 4 (nibble bit width) because we
    // can only print the value as hex nibbles.
    let nibbleBitWidth = 4
    let segmentWidth = 4
    let bitWidth = requestedBitWidth ?? typeBitWidth
    let roundedBitWidth = bitWidth.roundUp(toMultipleOf: nibbleBitWidth)
    let digits = roundedBitWidth / nibbleBitWidth
    let digitsBeforeSeparator = digits % segmentWidth

    // Left shift by dropped bits and right shift by the padding bits.
    let droppedBitWidth = typeBitWidth - bitWidth
    let paddingBitWidth = roundedBitWidth - bitWidth
    precondition(
      MemoryLayout<Integer>.size == MemoryLayout<Integer.Magnitude>.size)
    var value = Integer.Magnitude(truncatingIfNeeded: value)
    value <<= droppedBitWidth
    value >>= paddingBitWidth
    let nibbleMask = Integer.Magnitude(0b1111)

    self.appendLiteral("0x")
    for digit in 0..<digits {
      if digit != 0, (digit - digitsBeforeSeparator) % segmentWidth == 0 {
        self.appendLiteral("_")
      }

      let nibble = (value >> (typeBitWidth - nibbleBitWidth)) & nibbleMask
      self.appendInterpolation(hexNibble: nibble)
      value <<= nibbleBitWidth
    }
  }
}
