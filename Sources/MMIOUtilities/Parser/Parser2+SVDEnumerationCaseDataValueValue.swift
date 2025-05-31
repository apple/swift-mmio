//
//  EnumeratedValueDataTypePrefix.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 5/30/25.
//

fileprivate enum SVDEnumerationCaseDataValueValueDigitParser2 {
  case binary
  case decimal
  case hexadecimal
}

public struct SVDEnumerationCaseDataValueValueParser2<Integer>: Parser2
where Integer: FixedWidthInteger {
  public typealias Input = String.UTF8View.SubSequence
  public typealias Output = (Integer, Integer)

  public static func parse(_ input: inout Input) -> Output? {
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
        guard let digit = BinaryOrAnyDigitParser2.parse(&input)
        else { break loop }
        digitValue = Integer(digit.0)
        digitMask = Integer(digit.1)

      case .decimal:
        // Attempt to parse a digit.
        guard let digit = DecimalDigitParser2.parse(&input)
        else { break loop }
        digitValue = Integer(digit)
        digitMask = 1

      case .hexadecimal:
        // Attempt to parse a digit.
        guard let digit = HexadecimalDigitParser2.parse(&input)
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
