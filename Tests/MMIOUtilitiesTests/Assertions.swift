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

import MMIOUtilities
import Testing

func assertParse<Output>(
  _ parser: Parser<Substring, Output>,
  _ input: String,
  _ expected: Output,
  sourceLocation: SourceLocation = #_sourceLocation
) where Output: Equatable {
  var input = input[...]
  let parsed = parser.run(&input)

  do {
    let parsed = try #require(
      parsed,
      "Failed to parse input",
      sourceLocation: sourceLocation)
    try #require(
      parsed == expected,
      "Parsed value '\(parsed)' does not match expected value '\(expected)'",
      sourceLocation: sourceLocation)
    try #require(
      input.isEmpty,
      "Failed to fully consume input, remaining: '\(input)'",
      sourceLocation: sourceLocation)
  } catch {}
}

func assertNoParse<Output>(
  _ parser: Parser<Substring, Output>,
  _ input: String,
  sourceLocation: SourceLocation = #_sourceLocation
) where Output: Equatable {
  var input = input[...]
  let original = input
  let parsed = parser.run(&input)
  #expect(parsed == nil, sourceLocation: sourceLocation)
  #expect(input == original, sourceLocation: sourceLocation)
}

func assertParse2<Parser, Output>(
  _ parser: Parser.Type,
  _ input: String,
  _ expected: Output,
  sourceLocation: SourceLocation = #_sourceLocation
) where Parser: Parser2<String.UTF8View.SubSequence, Output>, Parser.Output: Equatable {
  var input = input.utf8[...]
  let parsed = Parser.parse(&input)

  do {
    let parsed = try #require(
      parsed,
      "Failed to parse input",
      sourceLocation: sourceLocation)
    try #require(
      parsed == expected,
      "Parsed value '\(parsed)' does not match expected value '\(expected)'",
      sourceLocation: sourceLocation)
    try #require(
      input.isEmpty,
      "Failed to fully consume input, remaining: '\(input)'",
      sourceLocation: sourceLocation)
  } catch {}
}

func assertNoParse2<Parser, Output>(
  _ parser: Parser.Type,
  _ input: String,
  sourceLocation: SourceLocation = #_sourceLocation
) where Parser: Parser2<String.UTF8View.SubSequence, Output>, Parser.Output: Equatable {
  var input = input.utf8[...]
  let original = input
  let parsed = Parser.parse(&input)
  #expect(parsed == nil, sourceLocation: sourceLocation)
  #expect(input == original, sourceLocation: sourceLocation)
}
