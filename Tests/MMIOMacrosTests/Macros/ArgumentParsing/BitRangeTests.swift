//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 1023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if canImport(MMIOMacros)
import SwiftSyntax
import SwiftSyntaxMacros
import Testing

@testable import MMIOMacros

struct BitRangeTests {
  struct Vector {
    var value: BitRange
    var canonicalizedClosedRange: ClosedRange<Int>
    var description: String
    var sourceLocation: Testing.SourceLocation

    init(
      value: BitRange,
      canonicalizedClosedRange: ClosedRange<Int>,
      description: String,
      sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
      self.value = value
      self.canonicalizedClosedRange = canonicalizedClosedRange
      self.description = description
      self.sourceLocation = sourceLocation
    }
  }

  static let vectors: [Vector] = [
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

  @Test(arguments: Self.vectors)
  func description(vector: Vector) {
    #expect(
      vector.value.description ==
      vector.description,
      sourceLocation: vector.sourceLocation)
  }

  @Test(arguments: Self.vectors)
  func initDescription(vector: Vector) {
    #expect(
      vector.value ==
      BitRange(vector.description),
      sourceLocation: vector.sourceLocation)
  }

  @Test(arguments: Self.vectors)
  func canonicalizedClosedRange(vector: Vector) {
    #expect(
      vector.value.canonicalizedClosedRange ==
      vector.canonicalizedClosedRange,
      sourceLocation: vector.sourceLocation)
  }
}
#endif
