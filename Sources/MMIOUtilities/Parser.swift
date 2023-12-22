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
      let endIndex = input.firstIndex(of: element) ?? input.endIndex
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

extension Parser where Output == Void {
  public func take<B>(_ p: Parser<Input, B>) -> Parser<Input, B> {
    zip(self, p).map { a, b in b }
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

extension Parser {
  public func oneOrMore(
    separatedBy separator: Parser<Input, Void>
  ) -> Parser<Input, [Output]> {
    Parser<Input, [Output]> { input in
      guard let match = self.run(&input) else { return nil }
      var matches = [match]
      while true {
        let remaining = input
        guard
          let _ = separator.run(&input),
          let match = self.run(&input)
        else {
          input = remaining
          break
        }
        matches.append(match)
      }
      return matches
    }
  }
}
