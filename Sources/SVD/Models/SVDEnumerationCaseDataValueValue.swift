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
public import XML

/// literal format: `[+]?(((0x|0X)[0-9a-fA-F]+)|([0-9]+)|((#|0b)[01xX]+))`.
public struct SVDEnumerationCaseDataValueValue {
  public var value: UInt64
  public var mask: UInt64
}

extension SVDEnumerationCaseDataValueValue {
  public func description(bitWidth: Int) -> String {
    guard bitWidth > 0 else { return "" }
    var description = "0b"

    var needle: UInt64 = 1 << (bitWidth - 1)
    while needle > 0 {
      if self.mask & needle == 0 {
        description.append("x")
      } else if self.value & needle > 0 {
        description += "1"
      } else {
        description += "0"
      }
      needle >>= 1
    }

    return description
  }
}

extension SVDEnumerationCaseDataValueValue: Decodable {}

extension SVDEnumerationCaseDataValueValue: Encodable {}

extension SVDEnumerationCaseDataValueValue: Equatable {}

extension SVDEnumerationCaseDataValueValue: Hashable {}

extension SVDEnumerationCaseDataValueValue: Sendable {}

extension SVDEnumerationCaseDataValueValue: XMLElementInitializable {
  public init(_ element: borrowing XMLElement) throws {
    let stringValue = try String(element)
    let parser = SVDEnumerationCaseDataValueValueParser<UInt64>()
    guard let value = parser.parseAll(stringValue)
    else { throw XMLError.unknownValue(stringValue) }
    self.value = value.0
    self.mask = value.1
  }
}

private struct SVDEnumerationCaseDataValueValueParser<Integer>: ParserProtocol
where Integer: FixedWidthInteger {
  typealias Output = (Integer, Integer)

  func parse(_ input: inout Input) -> Output? {
    let original = input

    if input.first == UInt8(ascii: "+") {
      input.removeFirst()
    }

    let base: Integer
    if input.first == UInt8(ascii: "#") {
      input.removeFirst()
      base = 2
    } else if input.starts(with: "0b".utf8) {
      input.removeFirst(2)
      base = 2
    } else if input.starts(with: "0x".utf8) || input.starts(with: "0X".utf8) {
      input.removeFirst(2)
      base = 16
    } else {
      base = 10
    }

    var value = Integer(0)
    var mask = Integer(0) &- 1
    var digitsConsumed = false
    while let (digit, digitMask) = input.first.flatMap({
      Self.digit($0, base: base)
    }) {
      input.removeFirst()
      if base == 2 {
        mask = mask << 1 | digitMask
      }

      // Add the digit to the parsed value.
      guard value.incrementalParseAppend(digit: digit, base: base) else {
        // Exit early on overflow.
        input = original
        return nil
      }

      digitsConsumed = true
    }

    guard digitsConsumed else {
      input = original
      return nil
    }

    return (value, mask)
  }

  /// Returns the value and mask of a digit in the base.
  ///
  /// Binary digits "x" and "X" have a value and mask of 0.
  static func digit(_ ascii: UInt8, base: Integer) -> (Integer, Integer)? {
    let digit: Integer
    switch ascii {
    case UInt8(ascii: "x"), UInt8(ascii: "X"):
      guard base == 2 else { return nil }
      return (0, 0)
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      digit = Integer(ascii - UInt8(ascii: "0"))
    case UInt8(ascii: "a")...UInt8(ascii: "f"):
      digit = Integer(ascii - UInt8(ascii: "a") + 10)
    case UInt8(ascii: "A")...UInt8(ascii: "F"):
      digit = Integer(ascii - UInt8(ascii: "A") + 10)
    default:
      return nil
    }
    guard digit < base else { return nil }
    return (digit, 1)
  }
}
