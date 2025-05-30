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

// MARK: - Base

struct BaseParser: ParserProtocol {
  typealias Output = Void

  func parse(_ input: inout Input) -> Output? { () }
}

// MARK: - Conversion

extension ParserProtocol {
  public func map<NewOutput>(
    _ mapping: sending @escaping (Output) -> NewOutput?
  ) -> some ParserProtocol<NewOutput> {
    MappingParser(parser: self, mapping: mapping)
  }
}

private struct MappingParser<Parser, Output>: ParserProtocol
where Parser: ParserProtocol {
  var parser: Parser
  var mapping: (Parser.Output) -> Output?

  func parse(_ input: inout Input) -> Output? {
    let original = input
    guard
      let parserOutput = self.parser.parse(&input),
      let output = self.mapping(parserOutput)
    else {
      input = original
      return nil
    }
    return output
  }
}

// MARK: - Collection

extension ParserProtocol {
  public func skip<P>(
    _ p: P
  ) -> some ParserProtocol<Output>
  where P: ParserProtocol {
    Take0Parser(parser0: self, parser1: p)
  }
}

extension ParserProtocol where Self.Output == Void {
  public func take<P>(
    _ p: P
  ) -> some ParserProtocol<P.Output>
  where P: ParserProtocol {
    Take1Parser(parser0: self, parser1: p)
  }
}

extension ParserProtocol {
  // Output == (A)
  public func take<Parser>(
    _ parser: Parser
  ) -> some ParserProtocol<(Output, Parser.Output)>
  where Parser: ParserProtocol {
    Take01Parser(parser0: self, parser1: parser)
  }

  // Output == (A, B)
  public func take<Parser, A, B>(
    _ parser: Parser
  ) -> some ParserProtocol<(A, B, Parser.Output)>
  where Parser: ParserProtocol, Output == (A, B) {
    Take01Parser(parser0: self, parser1: parser).map {
      ($0.0, $0.1, $1)
    }
  }

  // Output == (A, B, C)
  public func take<Parser, A, B, C>(
    _ parser: Parser
  ) -> some ParserProtocol<(A, B, C, Parser.Output)>
  where Parser: ParserProtocol, Output == (A, B, C) {
    Take01Parser(parser0: self, parser1: parser).map {
      ($0.0, $0.1, $0.2, $1)
    }
  }

  // Output == (A, B, C, D)
  public func take<Parser, A, B, C, D>(
    _ parser: Parser
  ) -> some ParserProtocol<(A, B, C, D, Parser.Output)>
  where Parser: ParserProtocol, Output == (A, B, C, D) {
    Take01Parser(parser0: self, parser1: parser).map {
      ($0.0, $0.1, $0.2, $0.3, $1)
    }
  }

  // Output == (A, B, C, D, E)
  public func take<Parser, A, B, C, D, E>(
    _ parser: Parser
  ) -> some ParserProtocol<(A, B, C, D, E, Parser.Output)>
  where Parser: ParserProtocol, Output == (A, B, C, D, E) {
    Take01Parser(parser0: self, parser1: parser).map {
      ($0.0, $0.1, $0.2, $0.3, $0.4, $1)
    }
  }
}

private struct Take0Parser<Parser0, Parser1>: ParserProtocol
where Parser0: ParserProtocol, Parser1: ParserProtocol {
  typealias Output = Parser0.Output

  var parser0: Parser0
  var parser1: Parser1

  func parse(_ input: inout Input) -> Output? {
    let original = input
    if let output0 = self.parser0.parse(&input),
      self.parser1.parse(&input) != nil
    {
      return output0
    } else {
      input = original
      return nil
    }
  }
}

private struct Take1Parser<Parser0, Parser1>: ParserProtocol
where Parser0: ParserProtocol, Parser1: ParserProtocol {
  typealias Output = Parser1.Output

  var parser0: Parser0
  var parser1: Parser1

  func parse(_ input: inout Input) -> Output? {
    let original = input
    if self.parser0.parse(&input) != nil,
      let output1 = self.parser1.parse(&input)
    {
      return output1
    } else {
      input = original
      return nil
    }
  }
}

private struct Take01Parser<Parser0, Parser1>: ParserProtocol
where Parser0: ParserProtocol, Parser1: ParserProtocol {
  typealias Output = (Parser0.Output, Parser1.Output)

  var parser0: Parser0
  var parser1: Parser1

  func parse(_ input: inout Input) -> Output? {
    let original = input
    if let output0 = self.parser0.parse(&input),
      let output1 = self.parser1.parse(&input)
    {
      return (output0, output1)
    } else {
      input = original
      return nil
    }
  }
}

// MARK: - Choice

public struct OneOfParser<Output>: ParserProtocol {
  var matches: [(match: String, output: Output)]

  public init(_ matches: (match: String, output: Output)...) {
    self.matches = matches
  }

  public func parse(_ input: inout Input) -> Output? {
    for (match, output) in self.matches {
      if input.starts(with: match.utf8[...]) {
        input.removeFirst(match.count)
        return output
      }
    }
    return nil
  }
}

extension OneOfParser
where Output: CaseIterable, Output: RawRepresentable, Output.RawValue == String
{
  init() {
    self.matches = Output.allCases.map { ($0.rawValue, $0) }
  }
}

// MARK: - Repeat

struct ZeroOrMoreParser<Parser>: ParserProtocol where Parser: ParserProtocol {
  typealias Output = [Parser.Output]

  var parser: Parser
  var separator: DropParser

  init(parser: Parser, separator: String) {
    self.parser = parser
    self.separator = DropParser(separator)
  }

  func parse(_ input: inout Input) -> Output? {
    var matches = Output()
    var remaining = input
    while let match = self.parser.parse(&input) {
      matches.append(match)
      remaining = input
      guard self.separator.parse(&input) != nil else { break }
    }
    input = remaining
    return matches
  }
}
