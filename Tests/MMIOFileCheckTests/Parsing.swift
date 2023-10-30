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
// Shout out to point free's https://www.pointfree.co/collections/parsing series
// by Brandon Williams and Stephen Celis which served as a great basis to
// understand performant and ergonomic parsing.

struct Parser<Input, Output> {
  let parse: (inout Input) -> Output?

  func parse(_ input: inout Input) -> (match: Output?, rest: Input) {
    let match = self.parse(&input)
    return (match, input)
  }
}

// MARK: - Prefixes
extension Parser: ExpressibleByUnicodeScalarLiteral where Input == Substring, Output == Void {
  typealias UnicodeScalarLiteralType = StringLiteralType
}

extension Parser: ExpressibleByExtendedGraphemeClusterLiteral where Input == Substring, Output == Void {
  typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
}

extension Parser: ExpressibleByStringLiteral where Input == Substring, Output == Void {
  typealias StringLiteralType = String

  init(stringLiteral value: String) {
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
  static func dropPrefix(_ p: Input.SubSequence) -> Self {
    Self { input in
      guard input.starts(with: p) else { return nil }
      input.removeFirst(p.count)
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
  static func prefix(upTo element: Input.Element) -> Self {
    Self { input in
      guard let endIndex = input.firstIndex(of: element) else { return nil }
      let match = input[..<endIndex]
      input = input[endIndex...]
      return match
    }
  }
}

// MARK: - Selectors
func zip<Input, A, B>(
  _ p1: Parser<Input, A>,
  _ p2: Parser<Input, B>
) -> Parser<Input, (A, B)> {
  .init { input -> (A, B)? in
    let original = input
    guard let output1 = p1.parse(&input) else { return nil }
    guard let output2 = p2.parse(&input) else {
      input = original
      return nil
    }
    return (output1, output2)
  }
}

extension Parser {
  func map<T>(_ f: @escaping (Output) -> T) -> Parser<Input, T> {
    .init { input in self.parse(&input).map(f) }
  }
}

extension Parser {
  static func skip(_ p: Self) -> Parser<Input, Void> {
    p.map { _ in () }
  }

  func skip<B>(_ p: Parser<Input, B>) -> Self {
    zip(self, p).map { a, _ in a }
  }
}

extension Parser {
  static func take(_ p: Self) -> Self { p }

  // Output == A
  func take<B>(_ p: Parser<Input, B>) -> Parser<Input, (Output, B)> {
    zip(self, p).map { a, b in (a, b) }
  }

  func take<A, B, C>(_ p: Parser<Input, C>) -> Parser<Input, (A, B, C)>
  where Output == (A, B) {
    zip(self, p).map { ab, c in (ab.0, ab.1, c) }
  }

  func take<A, B, C, D>(_ p: Parser<Input, D>) -> Parser<Input, (A, B, C, D)>
  where Output == (A, B, C) {
    zip(self, p).map { abc, d in (abc.0, abc.1, abc.2, d) }
  }

  func take<A, B, C, D, E>(_ p: Parser<Input, E>) -> Parser<Input, (A, B, C, D, E)>
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
