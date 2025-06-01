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

// Inspired by a couple of Swift community parser combinator libraries, like
// swift-parsing, SwiftParsec, and others.

public protocol ParserProtocol<Output>: Sendable {
  typealias Input = String.UTF8View.SubSequence
  associatedtype Output

  func parse(_ input: inout Input) -> Output?
}

extension ParserProtocol {
  public func parseAll(_ input: String) -> Output? {
    var input = input.utf8[...]
    guard let output = self.parse(&input), input.isEmpty else { return nil }
    return output
  }
}
