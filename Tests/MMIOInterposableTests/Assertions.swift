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

func assertMMIOAlignment<Value>(
  pointer: UnsafePointer<Value>,
  sourceLocation: SourceLocation = #_sourceLocation
) where Value: FixedWidthInteger & UnsignedInteger {
  let address = UInt(bitPattern: pointer)
  let alignment = UInt(MemoryLayout<Value>.alignment)
  #expect(
    address.isMultiple(of: alignment),
    """
    Invalid load or store of type '\(Value.self)' from unaligned address \
    '\(hex: address)'
    """,
    sourceLocation: sourceLocation)
}

func assertMMIOInterposerTrace(
  interposer: MMIOTracingInterposer,
  trace: [MMIOTracingInterposerEvent],
  sourceLocation: SourceLocation = #_sourceLocation
) {
  // Exit early if the actual trace matches the expected trace.
  let actualTrace = interposer.trace
  let expectedTrace = trace
  guard actualTrace != expectedTrace else { return }

  Issue.record(
    Comment(
      rawValue: diff(
        expected: expectedTrace, actual: actualTrace, noun: "trace")),
    sourceLocation: sourceLocation)
}
