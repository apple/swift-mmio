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

import MMIO
import MMIOUtilities
import XCTest

class MMIOTracingInterposer {
  // This could be made more efficient by mapping to 8 byte blocks.
  // Note: memory is stored as little endian
  var memory: [UInt: UInt8]
  var trace: [MMIOTracingInterposerEvent]

  init() {
    self.memory = .init()
    self.trace = .init()
  }
}

extension MMIOTracingInterposer: MMIOInterposer {
  func load<Value>(
    from pointer: UnsafePointer<Value>
  ) -> Value where Value: FixedWidthInteger & UnsignedInteger {
    XCTAssertMMIOAlignment(pointer: pointer)

    let address = UInt(bitPattern: pointer)
    let size = MemoryLayout<Value>.size

    var value = Value(0)
    for offset in 0..<UInt(size) {
      let byte = self.memory[address + (UInt(size) - 1 - offset), default: 0]
      value <<= 8
      value |= Value(byte)
    }

    self.trace.append(
      .init(
        load: true,
        address: address,
        size: size,
        value: UInt64(value)))

    return value
  }

  func store<Value>(
    _ value: Value,
    to pointer: UnsafeMutablePointer<Value>
  ) where Value: FixedWidthInteger & UnsignedInteger {
    XCTAssertMMIOAlignment(pointer: pointer)

    let address = UInt(bitPattern: pointer)
    let size = MemoryLayout<Value>.size

    var storedValue = value
    for offset in 0..<UInt(size) {
      self.memory[address + offset] = UInt8(truncatingIfNeeded: storedValue)
      storedValue >>= 8
    }

    self.trace.append(
      .init(
        load: false,
        address: address,
        size: size,
        value: UInt64(value)))
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
func XCTAssertMMIOAlignment<Value>(
  pointer: UnsafePointer<Value>,
  file: StaticString = #file,
  line: UInt = #line
) where Value: FixedWidthInteger & UnsignedInteger {
  let address = UInt(bitPattern: pointer)
  let alignment = UInt(MemoryLayout<Value>.alignment)
  if !address.isMultiple(of: alignment) {
    XCTFail(
      """
      Invalid load or store of type '\(Value.self)' from unaligned address \
      '\(hex: UInt(bitPattern: pointer))'
      """,
      file: file,
      line: line)
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
func XCTAssertMMIOInterposerTrace(
  interposer: MMIOTracingInterposer,
  trace: [MMIOTracingInterposerEvent],
  file: StaticString = #file,
  line: UInt = #line
) {
  // Exit early if the actual trace matches the expected trace.
  let actualTrace = interposer.trace
  let expectedTrace = trace
  guard actualTrace != expectedTrace else { return }

  let failureMessage = formatTraceDiff(
    expectedTrace: expectedTrace,
    actualTrace: actualTrace)

  XCTFail(failureMessage, file: file, line: line)
}

func formatTraceDiff(
  expectedTrace: [MMIOTracingInterposerEvent],
  actualTrace: [MMIOTracingInterposerEvent],
  simple: Bool = false
) -> String {
  assert(expectedTrace != actualTrace)

  let failureMessage: String

  // Use `CollectionDifference` on supported platforms to get `diff`-like
  // line-based output. On older platforms, fall back to simple string
  // comparison.
  if !simple, #available(macOS 10.15, *) {
    let difference = actualTrace.difference(from: expectedTrace)

    var result = ""

    var insertions = [Int: MMIOTracingInterposerEvent]()
    var removals = [Int: MMIOTracingInterposerEvent]()

    for change in difference {
      switch change {
      case .insert(let offset, let element, _):
        insertions[offset] = element
      case .remove(let offset, let element, _):
        removals[offset] = element
      }
    }

    var expectedLine = 0
    var actualLine = 0

    while expectedLine < expectedTrace.count || actualLine < actualTrace.count {
      if let removal = removals[expectedLine] {
        result += "-\(removal)\n"
        expectedLine += 1
      } else if let insertion = insertions[actualLine] {
        result += "+\(insertion)\n"
        actualLine += 1
      } else {
        result += " \(expectedTrace[expectedLine])\n"
        expectedLine += 1
        actualLine += 1
      }
    }

    result.removeLast()
    failureMessage = """
      Actual trace (+) differed from expected trace (-):
      \(result)
      """
  } else {
    // Fall back to simple message on platforms that don't support
    // CollectionDifference.
    failureMessage = """
      Actual trace differed from expected trace:
      Actual:
      \(actualTrace.map(\.description).joined(separator: "\n"))

      Expected:
      \(expectedTrace.map(\.description).joined(separator: "\n"))
      """
  }

  return failureMessage
}
