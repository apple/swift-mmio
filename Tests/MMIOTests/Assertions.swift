//===----------------------------------------------------------------------===//
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

@testable import MMIO

func assertExtract<Storage>(
  bitRanges: Range<Int>...,
  from storage: Storage,
  equals expected: Storage,
  sourceLocation: SourceLocation = #_sourceLocation
) where Storage: FixedWidthInteger {
  let actual = storage[bits: bitRanges]
  #expect(
    actual == expected,
    Comment(
      rawValue: """
        Extracting value \
        from '\(hex: storage)' \
        at bit ranges \(bitRanges
          .map { "\($0.lowerBound)..<\($0.upperBound)" }
          .joined(separator: ", "))] \
        resulted in '\(hex: actual)', \
        but expected '\(hex: expected)'
        """),
    sourceLocation: sourceLocation)
}

func assertInsert<Storage>(
  value: Storage,
  bitRanges: Range<Int>...,
  into storage: Storage,
  equals expected: Storage,
  sourceLocation: SourceLocation = #_sourceLocation
) where Storage: FixedWidthInteger {
  var actual = storage
  actual[bits: bitRanges] = value
  #expect(
    actual == expected,
    Comment(
      rawValue: """
        Inserting '\(hex: value)' \
        into '\(hex: storage)' \
        at bit ranges [\(bitRanges
          .map { "\($0.lowerBound)..<\($0.upperBound)" }
          .joined(separator: ", "))] \
        resulted in '\(hex: actual)', \
        but expected to get '\(hex: expected)'
        """),
    sourceLocation: sourceLocation)
}
