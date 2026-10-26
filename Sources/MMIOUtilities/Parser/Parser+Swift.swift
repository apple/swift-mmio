//===----------------------------------------------------------------------===//
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

/// Parses an integer with an optional leading sign, such as `-0x1f`.
public struct SwiftIntegerParser<Output>: ParserProtocol
where Output: FixedWidthInteger {
  public init() {}

  public func parse(_ input: inout Input) -> Output? {
    let original = input

    let negated: Bool
    switch input.first {
    case UInt8(ascii: "-"):
      negated = true
      input.removeFirst()
    case UInt8(ascii: "+"):
      negated = false
      input.removeFirst()
    default:
      negated = false
    }

    let literalParser = SwiftIntegerLiteralParser<Output>(negated: negated)
    guard let value = literalParser.parse(&input) else {
      input = original
      return nil
    }
    return value
  }
}

/// Parses an unsigned Swift integer literal, such as `0x1f`, and returns its
/// value, or the negation of its value if `negated` is true.
///
/// A Swift integer literal never contains a sign; `-3` is the prefix operator
/// `-` applied to the literal `3`. Negating during parsing, and not after,
/// parses `Output.min`, whose magnitude does not fit in `Output`.
public struct SwiftIntegerLiteralParser<Output>: ParserProtocol
where Output: FixedWidthInteger {
  let negated: Bool

  public init(negated: Bool = false) {
    self.negated = negated
  }

  public func parse(_ input: inout Input) -> Output? {
    let original = input

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
      // Accumulate in the direction of the sign, so a negated literal can
      // reach `Output.min` and an unsigned one fails instead of trapping.
      let shifted = value.multipliedReportingOverflow(
        by: Output(parserAndBase.base))
      let appended =
        self.negated
        ? shifted.partialValue.subtractingReportingOverflow(Output(digit))
        : shifted.partialValue.addingReportingOverflow(Output(digit))
      guard !shifted.overflow, !appended.overflow else {
        input = original
        return nil
      }
      value = appended.partialValue

      digitsConsumed = true
      while input.first == UInt8(ascii: "_") {
        _ = input.removeFirst()
      }
    }

    guard digitsConsumed else {
      input = original
      return nil
    }

    return value
  }
}
