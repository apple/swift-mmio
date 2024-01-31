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

import MMIOInterposable
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

    self.trace.append(.load(of: value, from: address))

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

    self.trace.append(.store(of: value, to: address))
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

  XCTFail(
    diff(expected: expectedTrace, actual: actualTrace, noun: "trace"),
    file: file,
    line: line)
}
