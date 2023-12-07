//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// Inspired by a couple of Swift community parser combinator libraries, like
// swift-parsing, SwiftParsec, and others.
//
// Shout out to point-free's https://www.pointfree.co/collections/parsing series
// by Brandon Williams and Stephen Celis which served as a great basis to
// understand performant and ergonomic parsing.

public struct Parser<Input, Output> {
  public let run: (inout Input) -> Output?

  public init(run: @escaping (inout Input) -> Output?) {
    self.run = run
  }
}

// MARK: - Prefixes
extension Parser: ExpressibleByUnicodeScalarLiteral
where Input == Substring, Output == Void {
  public typealias UnicodeScalarLiteralType = StringLiteralType
}

extension Parser: ExpressibleByExtendedGraphemeClusterLiteral
where Input == Substring, Output == Void {
  public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
}

extension Parser: ExpressibleByStringLiteral
where Input == Substring, Output == Void {
  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self = .dropPrefix(value[...])
  }
}

extension Parser
where
  Input: Collection,
  Input.SubSequence == Input,
  Input.Element: Equatable,
  Output == Void
{
  public static func dropPrefix(_ prefix: Input.SubSequence) -> Self {
    Self { input in
      guard input.starts(with: prefix) else { return nil }
      input.removeFirst(prefix.count)
      return ()
    }
  }
}

extension Parser
where
  Input: Collection,
  Input.SubSequence == Input,
  Input.Element: Equatable,
  Output == Input
{
  public static func prefix(upTo element: Input.Element) -> Self {
    Self { input in
      guard let endIndex = input.firstIndex(of: element) else { return nil }
      let match = input[..<endIndex]
      input = input[endIndex...]
      return match
    }
  }
}

// MARK: - Selectors
public func zip<Input, A, B>(
  _ p1: Parser<Input, A>,
  _ p2: Parser<Input, B>
) -> Parser<Input, (A, B)> {
  .init { input -> (A, B)? in
    let original = input
    guard let output1 = p1.run(&input) else { return nil }
    guard let output2 = p2.run(&input) else {
      input = original
      return nil
    }
    return (output1, output2)
  }
}

extension Parser {
  public func map<T>(_ f: @escaping (Output) -> T) -> Parser<Input, T> {
    .init { input in self.run(&input).map(f) }
  }
}

extension Parser {
  public static func skip(_ p: Self) -> Parser<Input, Void> {
    p.map { _ in () }
  }

  public func skip<B>(_ p: Parser<Input, B>) -> Self {
    zip(self, p).map { a, _ in a }
  }
}

extension Parser {
  public static func take(_ p: Self) -> Self { p }

  // Output == A
  public func take<B>(_ p: Parser<Input, B>) -> Parser<Input, (Output, B)> {
    zip(self, p).map { a, b in (a, b) }
  }

  public func take<A, B, C>(_ p: Parser<Input, C>) -> Parser<Input, (A, B, C)>
  where Output == (A, B) {
    zip(self, p).map { ab, c in (ab.0, ab.1, c) }
  }

  public func take<A, B, C, D>(_ p: Parser<Input, D>) -> Parser<Input, (A, B, C, D)>
  where Output == (A, B, C) {
    zip(self, p).map { abc, d in (abc.0, abc.1, abc.2, d) }
  }

  public func take<A, B, C, D, E>(_ p: Parser<Input, E>) -> Parser<Input, (A, B, C, D, E)>
  where Output == (A, B, C, D) {
    zip(self, p).map { abcd, e in (abcd.0, abcd.1, abcd.2, abcd.3, e) }
  }

  // FIXME: fails with internal error
  // <unknown>:0: error: INTERNAL ERROR: feature not implemented: reabstraction of pack values
  // func take<each A, B>(
  //   _ p: Parser<Input, B>
  // ) -> Parser<Input, (repeat each A, B)>
  // where Output == (repeat each A) {
  //   zip(self, p).map { a, b in (repeat each a, b) }
  // }
}

extension Parser {
  public static func oneOf(_ parsers: [Parser]) -> Parser {
    Self { input in
      for parser in parsers {
        if let value = parser.run(&input) { return value }
      }
      return nil
    }
  }
}

extension Parser where Input == Substring {
  public static func cases(_: Output.Type = Output.self) -> Self
  where Output: CaseIterable & RawRepresentable, Output.RawValue == String {
    Self { input in
      for `case` in Output.allCases {
        let prefix = `case`.rawValue[...]
        if input.starts(with: prefix) {
          input.removeFirst(prefix.count)
          return `case`
        }
      }
      return nil
    }
  }
}

// MARK: - Int
enum IntPrefix: String, CaseIterable {
  case binary = "0b"
  case octal = "0o"
  case hexadecimal = "0x"
}

extension Parser where Input == Substring, Output == Int {
  public static let swiftInteger = Self { input in
    let original = input

    var positive = true
    switch input.first?.asciiValue {
    case UInt8(ascii: "-"):
      positive = false
      input.removeFirst()
    case UInt8(ascii: "+"):
      positive = true
      input.removeFirst()
    default:
      break
    }

    let intPrefix = Parser<Input, IntPrefix>.cases().run(&input)

    var value = 0
    var digitsConsumed = false
    loop: while !input.isEmpty {
      switch intPrefix {
      case .binary:
        guard let digit = Parser.binaryDigit.run(&input) else { break loop }
        value = value * 2 + digit
      case .octal:
        guard let digit = Parser.octalDigit.run(&input) else { break loop }
        value = value * 8 + digit
      case nil:
        guard let digit = Parser.decimalDigit.run(&input) else { break loop }
        value = value * 10 + digit
      case .hexadecimal:
        guard let digit = Parser.hexadecimalDigit.run(&input) else { break loop }
        value = value * 16 + digit
      }
      digitsConsumed = true
      while input.first?.asciiValue == UInt8(ascii: "_") {
        _ = input.removeFirst()
      }
    }

    guard digitsConsumed else {
      input = original
      return nil
    }

    return positive ? value : -value
  }
}

extension Parser where Input == Substring, Output == Int {
  public static let binaryDigit = Self { input in
    guard let ascii = input.first?.asciiValue else { return nil }
    switch ascii {
    case UInt8(ascii: "0"), UInt8(ascii: "1"):
      _ = input.removeFirst()
      return Int(ascii - UInt8(ascii: "0"))
    default:
      return nil
    }
  }

  public static let octalDigit = Self { input in
    guard let ascii = input.first?.asciiValue else { return nil }
    switch ascii {
    case UInt8(ascii: "0")..<UInt8(ascii: "8"):
      _ = input.removeFirst()
      return Int(ascii - UInt8(ascii: "0"))
    default:
      return nil
    }
  }

  public static let decimalDigit = Self { input in
    guard let ascii = input.first?.asciiValue else { return nil }
    switch ascii {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      _ = input.removeFirst()
      return Int(ascii - UInt8(ascii: "0"))
    default:
      return nil
    }
  }

  public static let hexadecimalDigit = Self { input in
    guard let ascii = input.first?.asciiValue else { return nil }
    switch ascii {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      _ = input.removeFirst()
      return Int(ascii - UInt8(ascii: "0"))
    case UInt8(ascii: "a")...UInt8(ascii: "f"):
      _ = input.removeFirst()
      return Int(ascii - UInt8(ascii: "a") + 10)
    case UInt8(ascii: "A")...UInt8(ascii: "F"):
      _ = input.removeFirst()
      return Int(ascii - UInt8(ascii: "A") + 10)
    default:
      return nil
    }
  }
}
