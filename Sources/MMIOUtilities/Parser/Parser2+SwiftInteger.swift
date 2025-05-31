//
//  SwiftIntegerParser2.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 5/30/25.
//

public struct SwiftIntegerParser2<Output>: Parser2
where Output: FixedWidthInteger {
  public typealias Input = String.UTF8View.SubSequence

  public static func parse(_ input: inout Input) -> Output? {
    let original = input

    var positive = true
    switch input.first {
    case UInt8(ascii: "-"):
      positive = false
      input.removeFirst()
    case UInt8(ascii: "+"):
      positive = true
      input.removeFirst()
    default:
      break
    }

    let digitParser2: any Parser2<Input, UInt8>.Type
    let base: Output
    switch input.prefix(2) {
    case "0b".utf8[...]:
      digitParser2 = BinaryDigitParser2.self
      base = 2
      input.removeFirst(2)
    case "0o".utf8[...]:
      digitParser2 = OctalDigitParser2.self
      base = 8
      input.removeFirst(2)
    case "0x".utf8[...]:
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
      while input.first == UInt8(ascii: "_") {
        _ = input.removeFirst()
      }
    }

    guard digitsConsumed else {
      input = original
      return nil
    }

    return positive ? value : 0 - value
  }
}
