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

private struct ParserAndBase {
  var parser: any ParserProtocol<UInt8>
  var base: Int
}

public struct SwiftIntegerParser<Output>: ParserProtocol
where Output: FixedWidthInteger {
  public init() {}

  public func parse(_ input: inout Input) -> Output? {
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

    let oneOf = OneOfParser<ParserAndBase>(
      ("0b", .init(parser: BinaryDigitParser(), base: 2)),
      ("0o", .init(parser: OctalDigitParser(), base: 8)),
      ("0x", .init(parser: HexadecimalDigitParser(), base: 16)),
    )

    let parserAndBase =
      oneOf.parse(&input)
      ?? .init(parser: DecimalDigitParser(), base: 10)

    var value = Output(0)
    var digitsConsumed = false
    while !input.isEmpty {
      guard let digit = parserAndBase.parser.parse(&input) else { break }
      guard
        value.incrementalParseAppend(
          digit: Output(digit),
          base: Output(parserAndBase.base))
      else {
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
