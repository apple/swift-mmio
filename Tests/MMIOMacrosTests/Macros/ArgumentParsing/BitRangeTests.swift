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

#if canImport(MMIOMacros)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import MMIOMacros

struct BitRangeTests {
  struct BitRangeTestVector: CustomStringConvertible {
    static let vectors: [Self] = [
      .init(
        value: .init(
          lowerBound: nil,
          upperBound: nil),
        canonicalizedClosedRange: (.min)...(.max),
        description: "(-∞, +∞)"),

      .init(
        value: .init(
          lowerBound: .init(value: 0, inclusive: false),
          upperBound: nil),
        canonicalizedClosedRange: 1...(.max),
        description: "(0, +∞)"),
      .init(
        value: .init(
          lowerBound: .init(value: 0, inclusive: true),
          upperBound: nil),
        canonicalizedClosedRange: 0...(.max),
        description: "[0, +∞)"),
      .init(
        value: .init(
          lowerBound: nil,
          upperBound: .init(value: 2, inclusive: false)),
        canonicalizedClosedRange: (.min)...1,
        description: "(-∞, 2)"),
      .init(
        value: .init(
          lowerBound: nil,
          upperBound: .init(value: 2, inclusive: true)),
        canonicalizedClosedRange: (.min)...2,
        description: "(-∞, 2]"),

      .init(
        value: .init(
          lowerBound: .init(value: 0, inclusive: false),
          upperBound: .init(value: 2, inclusive: false)),
        canonicalizedClosedRange: 1...1,
        description: "(0, 2)"),
      .init(
        value: .init(
          lowerBound: .init(value: 0, inclusive: false),
          upperBound: .init(value: 2, inclusive: true)),
        canonicalizedClosedRange: 1...2,
        description: "(0, 2]"),
      .init(
        value: .init(
          lowerBound: .init(value: 0, inclusive: true),
          upperBound: .init(value: 2, inclusive: false)),
        canonicalizedClosedRange: 0...1,
        description: "[0, 2)"),
      .init(
        value: .init(
          lowerBound: .init(value: 0, inclusive: true),
          upperBound: .init(value: 2, inclusive: true)),
        canonicalizedClosedRange: 0...2,
        description: "[0, 2]"),
    ]

    var value: BitRange
    var canonicalizedClosedRange: ClosedRange<Int>
    var description: String
  }

  @Test(arguments: BitRangeTestVector.vectors)
  func description(vector: BitRangeTestVector) {
    #expect(vector.value.description == vector.description)
  }

  @Test(arguments: BitRangeTestVector.vectors)
  func initDescription(vector: BitRangeTestVector) {
    #expect(vector.value == BitRange(vector.description))
  }

  @Test(arguments: BitRangeTestVector.vectors)
  func canonicalizedClosedRange(vector: BitRangeTestVector) {
    #expect(
      vector.value.canonicalizedClosedRange == vector.canonicalizedClosedRange)
  }
}
#endif
