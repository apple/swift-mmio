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

private enum EnumerationParserAndBase {
  case binary(any ParserProtocol<(UInt8, UInt8)>)
  case other(any ParserProtocol<UInt8>)
}

private struct SVDEnumerationCaseDataValueValueParser<Integer>: ParserProtocol
where Integer: FixedWidthInteger {
  typealias Output = (Integer, Integer)

  func parse(_ input: inout Input) -> Output? {
    let original = input

    if input.first == UInt8(ascii: "+") {
      input.removeFirst()
    }

    let oneOf = OneOfParser<(EnumerationParserAndBase, Int)>(
      ("#", (.binary(BinaryOrAnyDigitParser()), 2)),
      ("0b", (.binary(BinaryOrAnyDigitParser()), 2)),
      ("0x", (.other(HexadecimalDigitParser()), 16)),
      ("0X", (.other(HexadecimalDigitParser()), 16)),
    )

    let parserAndBase =
      oneOf.parse(&input)
      ?? (.other(DecimalDigitParser()), 10)

    var value = Integer(0)
    var mask = Integer(0) &- 1
    var digitsConsumed = false
    loop: while !input.isEmpty {
      let digitValue: Integer

      switch parserAndBase.0 {
      case .binary(let parser):
        guard let digit = parser.parse(&input) else { break loop }
        digitValue = Integer(digit.0)
        mask = mask << 1 | Integer(digit.1)

      case .other(let parser):
        guard let digit = parser.parse(&input) else { break loop }
        digitValue = Integer(digit)
      }

      // Add the digit to the parsed value.
      guard
        value.incrementalParseAppend(
          digit: digitValue,
          base: Integer(parserAndBase.1))
      else {
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
}
