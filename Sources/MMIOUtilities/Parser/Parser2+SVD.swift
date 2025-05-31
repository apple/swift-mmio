//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Parser2 {
  public static func svdBitRangeLiteral(
  ) -> some ParserProtocol<String.UTF8View.SubSequence, (UInt64, UInt64)> {
    Parser2.prefix("[")
      .take(Parser2.swiftInteger(UInt64.self))
      .skip(Parser2.prefix(":"))
      .take(Parser2.swiftInteger(UInt64.self))
      .skip(Parser2.prefix(")"))
  }

  public static func svdCPURevision(
  ) -> some ParserProtocol<String.UTF8View.SubSequence, (UInt64, UInt64)> {
    Parser2.prefix("r")
      .take(Parser2.swiftInteger(UInt64.self))
      .skip(Parser2.prefix("p"))
      .take(Parser2.swiftInteger(UInt64.self))
  }

  public static func svdEnumerationCaseDataValueValue<Integer>(
    _: Integer.Type
  ) -> some ParserProtocol<String.UTF8View.SubSequence, (Integer, Integer)>
  where Integer: FixedWidthInteger {
    SVDEnumerationCaseDataValueValueParser2<Integer>()
  }

  public static func svdScaledNonNegativeInteger<Integer>(
    _: Integer.Type
  ) -> some ParserProtocol<String.UTF8View.SubSequence, Integer>
  where Integer: FixedWidthInteger {
    SVDScaledNonNegativeIntegerParser2<Integer>()
  }
}

fileprivate enum SVDEnumerationCaseDataValueValueDigitParser2 {
  case binary
  case decimal
  case hexadecimal
}

fileprivate struct SVDEnumerationCaseDataValueValueParser2<Integer>: ParserProtocol
where Integer: FixedWidthInteger {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = (Integer, Integer)

  func parse(_ input: inout Input) -> Output? {
    let original = input

    if input.first == UInt8(ascii: "+") {
      input.removeFirst()
    }

    let digitParser2: SVDEnumerationCaseDataValueValueDigitParser2
    let base: Integer
    if input.prefix(1) == "#".utf8[...] {
      digitParser2 = .binary
      base = 2
      input.removeFirst(1)
    } else {
      switch input.prefix(2) {
      case "0b".utf8[...]:
        digitParser2 = .binary
        base = 2
        input.removeFirst(2)
      case "0x".utf8[...], "0X".utf8[...]:
        digitParser2 = .hexadecimal
        base = 16
        input.removeFirst(2)
      default:
        digitParser2 = .decimal
        base = 10
      }
    }

    var value = Integer(0)
    var mask = Integer(0) &- 1
    var digitsConsumed = false
    loop: while !input.isEmpty {
      let digitMask: Integer
      let digitValue: Integer

      switch digitParser2 {
      case .binary:
        // Attempt to parse a digit.
        guard let digit = Parser2.binaryOrAnyDigit().parse(&input)
        else { break loop }
        digitValue = Integer(digit.0)
        digitMask = Integer(digit.1)

      case .decimal:
        // Attempt to parse a digit.
        guard let digit = Parser2.decimalDigit().parse(&input)
        else { break loop }
        digitValue = Integer(digit)
        digitMask = 1

      case .hexadecimal:
        // Attempt to parse a digit.
        guard let digit = Parser2.hexadecimalDigit().parse(&input)
        else { break loop }
        digitValue = Integer(digit)
        digitMask = 1
      }

      // Add the digit to the parsed value.
      guard value.incrementalParseAppend(digit: digitValue, base: base)
      else {
        // Exit early on overflow.
        input = original
        return nil
      }

      // Update the mask
      mask = mask << 1 | digitMask

      digitsConsumed = true
    }

    guard digitsConsumed else {
      input = original
      return nil
    }

    return (value, mask)
  }
}

fileprivate struct SVDScaledNonNegativeIntegerParser2<Output>: ParserProtocol
where Output: FixedWidthInteger {
  typealias Input = String.UTF8View.SubSequence

  func parse(_ input: inout Input) -> Output? {
    let original = input

    if input.first == UInt8(ascii: "+") {
      input.removeFirst()
    }

    let digitParser2: any ParserProtocol<Input, UInt8>
    let base: Output
    switch input.prefix(2) {
    // FIXME: this is wrong.
    case "#".utf8[...]:
      digitParser2 = Parser2.binaryDigit()
      base = 2
      input.removeFirst(2)
    case "0x".utf8[...], "0X".utf8[...]:
      digitParser2 = Parser2.hexadecimalDigit()
      base = 16
      input.removeFirst(2)
    default:
      digitParser2 = Parser2.decimalDigit()
      base = 10
    }

    var value = Output(0)
    var digitsConsumed = false
    loop: while !input.isEmpty {
      // Attempt to parse a digit.
      guard let digit = digitParser2.parse(&input) else { break loop }

      // Add the digit to the parsed value.
      guard value.incrementalParseAppend(digit: Output(digit), base: base)
      else {
        input = original
        return nil
      }

      digitsConsumed = true
    }

    guard digitsConsumed else {
      input = original
      return nil
    }

    // Parse suffix.
    switch input.first {
    case UInt8(ascii: "k"), UInt8(ascii: "K"):
      value *= 1_000
      input.removeFirst()
    case UInt8(ascii: "m"), UInt8(ascii: "M"):
      value *= 1_000_000
      input.removeFirst()
    case UInt8(ascii: "g"), UInt8(ascii: "G"):
      value *= 1_000_000_000
      input.removeFirst()
    case UInt8(ascii: "t"), UInt8(ascii: "T"):
      value *= 1_000_000_000_000
      input.removeFirst()
    default:
      break
    }

    return value
  }
}
