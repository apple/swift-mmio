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

struct ParserTests {
  func assertParse<Parser, Output>(
    _ parser: Parser,
    _ input: String,
    _ expected: Output,
    sourceLocation: SourceLocation = #_sourceLocation
  ) where Parser: ParserProtocol<Output>, Parser.Output: Equatable {
    var input = input.utf8[...]
    let parsed = parser.parse(&input)

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

  func assertNoParse<Parser, Output>(
    _ parser: Parser,
    _ input: String,
    sourceLocation: SourceLocation = #_sourceLocation
  ) where Parser: ParserProtocol<Output>, Parser.Output: Equatable {
    var input = input.utf8[...]
    let original = input
    let parsed = parser.parse(&input)
    #expect(parsed == nil, sourceLocation: sourceLocation)
    #expect(input.elementsEqual(original), sourceLocation: sourceLocation)
  }
}
