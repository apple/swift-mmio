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

protocol XMLElementInitializable {
  init(_ element: borrowing XMLElement) throws
}

extension XMLElementInitializable
where Self: LosslessStringConvertible {
  init(_ element: borrowing XMLElement) throws {
    let stringValue = try String(element)
    self =
      try Self
      .init(stringValue)
      .unwrap(or: XMLError.unknownValue(stringValue))
  }
}

extension XMLElementInitializable
where Self: RawRepresentable, Self.RawValue == String {
  init(_ element: borrowing XMLElement) throws {
    let stringValue = try String(element)
    self =
      try Self
      .init(rawValue: stringValue)
      .unwrap(or: XMLError.unknownValue(stringValue))
  }
}

extension String: XMLElementInitializable {
  init(_ element: borrowing XMLElement) throws {
    self = element.value ?? ""
  }
}

extension Bool: XMLElementInitializable {
  init(_ element: borrowing XMLElement) throws {
    let stringValue = try String(element)
    switch stringValue {
    case "1", "true": self = true
    case "0", "false": self = false
    default: fatalError()
    }
  }
}

// scaledNonNegativeInteger: /^[+]?(0x|0X|#)?[0-9a-fA-F]+[kmgtKMGT]?$/
extension UInt64: XMLElementInitializable {
  init(_ element: borrowing XMLElement) throws {
    let stringValue = try String(element)
    let parser = SVDScaledNonNegativeIntegerParser<Self>()
    guard let value = parser.parseAll(stringValue)
    else { throw XMLError.unknownValue(stringValue) }
    self = value
  }
}

private struct ParserAndBase {
  var parser: any ParserProtocol<UInt8>
  var base: Int
}

private struct SVDScaledNonNegativeIntegerParser<Output>: ParserProtocol
where Output: FixedWidthInteger {
  func parse(_ input: inout Input) -> Output? {
    let original = input

    if input.first == UInt8(ascii: "+") {
      input.removeFirst()
    }

    let oneOf = OneOfParser<ParserAndBase>(
      ("#", .init(parser: BinaryDigitParser(), base: 2)),
      ("0x", .init(parser: HexadecimalDigitParser(), base: 16)),
      ("0X", .init(parser: HexadecimalDigitParser(), base: 16)),
    )

    let parserAndBase =
      oneOf.parse(&input)
      ?? .init(parser: DecimalDigitParser(), base: 10)

    var value = Output(0)
    var digitsConsumed = false
    loop: while !input.isEmpty {
      guard let digit = parserAndBase.parser.parse(&input) else { break loop }
      guard
        value.incrementalParseAppend(
          digit: Output(digit),
          base: Output(parserAndBase.base))
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

    let scaleParser = OneOfParser<Output>(
      ("k", 1_000),
      ("K", 1_000),
      ("m", 1_000_000),
      ("M", 1_000_000),
      ("g", 1_000_000_000),
      ("G", 1_000_000_000),
      ("t", 1_000_000_000_000),
      ("T", 1_000_000_000_000),
    )

    if let scale = scaleParser.parse(&input) {
      value *= scale
    }

    return value
  }
}
