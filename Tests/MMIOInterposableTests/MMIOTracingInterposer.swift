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

import MMIOInterposable
import Testing

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
    assertMMIOAlignment(pointer: pointer)

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
    assertMMIOAlignment(pointer: pointer)

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
