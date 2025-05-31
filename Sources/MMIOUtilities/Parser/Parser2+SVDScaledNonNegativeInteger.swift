//
//  ScaledNonNegativeIntegerPrefix.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 5/30/25.
//


public struct SVDScaledNonNegativeIntegerParser2<Output>: Parser2
where Output: FixedWidthInteger {
  public typealias Input = String.UTF8View.SubSequence

  public static func parse(_ input: inout Input) -> Output? {
    let original = input

    if input.first == UInt8(ascii: "+") {
      input.removeFirst()
    }

    let digitParser2: any Parser2<Input, UInt8>.Type
    let base: Output
    switch input.prefix(2) {
    // FIXME: this is wrong.
    case "#".utf8[...]:
      digitParser2 = BinaryDigitParser2.self
      base = 2
      input.removeFirst(2)
    case "0x".utf8[...], "0X".utf8[...]:
      digitParser2 = HexadecimalDigitParser2.self
      base = 16
      input.removeFirst(2)
    default:
      digitParser2 = DecimalDigitParser2.self
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
