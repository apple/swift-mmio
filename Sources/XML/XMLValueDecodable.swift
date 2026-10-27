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

extension XMLValueDecodable where Self: LosslessStringConvertible {
  public init(_ text: XMLText) throws {
    let stringValue = String(text)
    self =
      try Self
      .init(stringValue)
      .unwrap(or: XMLError.unknownValue(stringValue))
  }
}

extension XMLValueDecodable
where Self: RawRepresentable, Self.RawValue == String {
  public init(_ text: XMLText) throws {
    let stringValue = String(text)
    self =
      try Self
      .init(rawValue: stringValue)
      .unwrap(or: XMLError.unknownValue(stringValue))
  }
}

extension String: XMLValueDecodable {}

extension Bool: XMLValueDecodable {
  public init(_ text: XMLText) throws {
    let stringValue = String(text)
    switch stringValue {
    case "1", "true": self = true
    case "0", "false": self = false
    default: throw XMLError.unknownValue(stringValue)
    }
  }
}

// scaledNonNegativeInteger: /^[+]?(0x|0X|#)?[0-9a-fA-F]+[kmgtKMGT]?$/
extension UInt64: XMLValueDecodable {
  public init(_ text: XMLText) throws {
    var input = text.bytes[...]
    let parser = SVDScaledNonNegativeIntegerParser<Self>()
    guard let value = parser.parse(&input), input.isEmpty
    else { throw XMLError.unknownValue(String(text)) }
    self = value
  }
}

private struct SVDScaledNonNegativeIntegerParser<Output>
where Output: FixedWidthInteger {
  func parse(_ input: inout Slice<UnsafeBufferPointer<UInt8>>) -> Output? {
    let original = input

    if input.first == UInt8(ascii: "+") {
      input.removeFirst()
    }

    let base: Output
    let second = input.dropFirst().first
    if input.first == UInt8(ascii: "#") {
      input.removeFirst()
      base = 2
    } else if input.first == UInt8(ascii: "0"),
      second == UInt8(ascii: "x") || second == UInt8(ascii: "X")
    {
      input.removeFirst(2)
      base = 16
    } else {
      base = 10
    }

    var value = Output(0)
    var digitsConsumed = false
    while let digit = input.first.flatMap({ Self.digit($0, base: base) }) {
      input.removeFirst()
      guard value.incrementalParseAppend(digit: digit, base: base) else {
        input = original
        return nil
      }
      digitsConsumed = true
    }

    guard digitsConsumed else {
      input = original
      return nil
    }

    let scale: Output
    switch input.first {
    case UInt8(ascii: "k"), UInt8(ascii: "K"): scale = 1_000
    case UInt8(ascii: "m"), UInt8(ascii: "M"): scale = 1_000_000
    case UInt8(ascii: "g"), UInt8(ascii: "G"): scale = 1_000_000_000
    case UInt8(ascii: "t"), UInt8(ascii: "T"): scale = 1_000_000_000_000
    default: return value
    }
    input.removeFirst()

    let scaled = value.multipliedReportingOverflow(by: scale)
    guard !scaled.overflow else {
      input = original
      return nil
    }
    return scaled.partialValue
  }

  static func digit(_ ascii: UInt8, base: Output) -> Output? {
    let digit: Output
    switch ascii {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      digit = Output(ascii - UInt8(ascii: "0"))
    case UInt8(ascii: "a")...UInt8(ascii: "f"):
      digit = Output(ascii - UInt8(ascii: "a") + 10)
    case UInt8(ascii: "A")...UInt8(ascii: "F"):
      digit = Output(ascii - UInt8(ascii: "A") + 10)
    default:
      return nil
    }
    guard digit < base else { return nil }
    return digit
  }
}
