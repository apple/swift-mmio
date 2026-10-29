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

extension SVDEnumerationCaseDataValueValue: CommonDecodable {
  public static func decode(
    from decoder: inout some CommonDecoder & ~Escapable
  ) throws(CodingError.Decoding) -> Self {
    try decoder.decodeString(Visitor())
  }

  struct Visitor: DecodingStringVisitor {
    typealias DecodedValue = SVDEnumerationCaseDataValueValue

    /// Parses `[+]?(#|0b|0x|0X)?[0-9a-fA-F]+`, where binary digits can also
    /// be `x` or `X` for "any value".
    func visitUTF8Bytes(
      _ buffer: UTF8Span
    ) throws(CodingError.Decoding) -> DecodedValue {
      let bytes = buffer.span
      var index = 0
      if index < bytes.count, bytes[index] == UInt8(ascii: "+") { index += 1 }
      var base: UInt64 = 10
      if index < bytes.count, bytes[index] == UInt8(ascii: "#") {
        index += 1
        base = 2
      } else if index + 1 < bytes.count, bytes[index] == UInt8(ascii: "0"),
        bytes[index + 1] == UInt8(ascii: "b")
      {
        index += 2
        base = 2
      } else if index + 1 < bytes.count, bytes[index] == UInt8(ascii: "0"),
        bytes[index + 1] == UInt8(ascii: "x")
          || bytes[index + 1] == UInt8(ascii: "X")
      {
        index += 2
        base = 16
      }

      var value: UInt64 = 0
      var mask: UInt64 = .max
      let digitsStart = index
      while index < bytes.count {
        let byte = bytes[index]
        var digitMask: UInt64 = 1
        let digit: UInt64
        switch byte {
        case UInt8(ascii: "x"), UInt8(ascii: "X"):
          digit = base == 2 ? 0 : .max
          digitMask = 0
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
          digit = UInt64(byte - UInt8(ascii: "0"))
        case UInt8(ascii: "a")...UInt8(ascii: "f"):
          digit = UInt64(byte - UInt8(ascii: "a") + 10)
        case UInt8(ascii: "A")...UInt8(ascii: "F"):
          digit = UInt64(byte - UInt8(ascii: "A") + 10)
        default:
          digit = .max
        }
        guard digit < base else { break }
        if base == 2 { mask = mask << 1 | digitMask }
        guard value.incrementalParseAppend(digit: digit, base: base) else {
          throw Self.error(buffer)
        }
        index += 1
      }
      guard index > digitsStart, index == bytes.count else {
        throw Self.error(buffer)
      }
      return SVDEnumerationCaseDataValueValue(value: value, mask: mask)
    }

    static func error(_ buffer: UTF8Span) -> CodingError.Decoding {
      let string = String(copying: buffer)
      return CodingError.dataCorrupted(
        debugDescription: "Invalid enumerated value '\(string)'")
    }
  }
}
