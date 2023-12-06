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

import SwiftSyntax
import SwiftSyntaxMacros
import XCTest

@testable import MMIOMacros

final class BitRangeTests: XCTestCase {
  struct Vector {
    var value: BitRange
    var canonicalizedClosedRange: ClosedRange<Int>
    var description: String
    var file: StaticString
    var line: UInt

    init(
      value: BitRange,
      canonicalizedClosedRange: ClosedRange<Int>,
      description: String,
      file: StaticString = #file,
      line: UInt = #line
    ) {
      self.value = value
      self.canonicalizedClosedRange = canonicalizedClosedRange
      self.description = description
      self.file = file
      self.line = line
    }
  }

  let vectors: [Vector] = [
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

  func test_description() {
    for vector in vectors {
      XCTAssertEqual(
        vector.value.description,
        vector.description,
        file: vector.file,
        line: vector.line)
    }
  }

  func test_initDescription() {
    for vector in vectors {
      XCTAssertEqual(
        vector.value,
        BitRange(vector.description),
        file: vector.file,
        line: vector.line)
    }
  }

  func test_canonicalizedClosedRange() {
    for vector in vectors {
      XCTAssertEqual(
        vector.value.canonicalizedClosedRange,
        vector.canonicalizedClosedRange,
        file: vector.file,
        line: vector.line)
    }
  }
}
