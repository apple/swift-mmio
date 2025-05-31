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
  public static func swiftInteger<Integer>(
    _: Integer.Type
  ) -> some ParserProtocol<String.UTF8View.SubSequence, Integer>
  where Integer: FixedWidthInteger {
    SwiftIntegerParser2<Integer>()
  }
}

fileprivate struct SwiftIntegerParser2<Output>: ParserProtocol
where Output: FixedWidthInteger {
  typealias Input = String.UTF8View.SubSequence

  func parse(_ input: inout Input) -> Output? {
    let original = input

    let positive: Bool
    switch input.first {
    case UInt8(ascii: "-"):
      positive = false
      input.removeFirst()
    case UInt8(ascii: "+"):
      positive = true
      input.removeFirst()
    default:
      positive = true
    }

    let digitParser2: any ParserProtocol<Input, UInt8>
    let base: Output
    switch input.prefix(2) {
    case "0b".utf8[...]:
      digitParser2 = Parser2.binaryDigit()
      base = 2
      input.removeFirst(2)
    case "0o".utf8[...]:
      digitParser2 = Parser2.octalDigit()
      base = 8
      input.removeFirst(2)
    case "0x".utf8[...]:
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
