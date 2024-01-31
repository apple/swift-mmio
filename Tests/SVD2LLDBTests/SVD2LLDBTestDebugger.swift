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

@testable import SVD2LLDB

struct SVD2LLDBTestDebugger {
  var rng: SVD2LLDBTestPRNG
  var trace: [SVD2LLDBTestDebuggerEvent]
}

extension SVD2LLDBTestDebugger {
  init() {
    self.rng = SVD2LLDBTestPRNG(seed: 0)
    self.trace = [SVD2LLDBTestDebuggerEvent]()
  }
}

extension SVD2LLDBTestDebugger: CustomStringConvertible {
  var description: String {
    self.trace.lazy.map(\.description).joined(separator: "\n")
  }
}

extension SVD2LLDBTestDebugger: SVD2LLDBDebugger {
  mutating func read(
    address: UInt64,
    bits: some FixedWidthInteger
  ) throws -> UInt64 {
    let lowerBound: UInt64 = 0
    let upperBound: UInt64 = 1 << bits
    let value = UInt64.random(in: lowerBound..<upperBound, using: &self.rng)
    self.trace.append(
      .init(
        read: true,
        address: address,
        bits: UInt64(bits),
        value: value))
    return value
  }

  mutating func write(
    address: UInt64,
    value: UInt64,
    bits: some FixedWidthInteger
  ) throws {
    self.trace.append(
      .init(
        read: false,
        address: address,
        bits: UInt64(bits),
        value: value))
  }
}

struct SVD2LLDBTestDebuggerEvent {
  var read: Bool
  var address: UInt64
  var bits: UInt64
  var value: UInt64
}

extension SVD2LLDBTestDebuggerEvent: Equatable {}

extension SVD2LLDBTestDebuggerEvent: CustomStringConvertible {
  var description: String {
    switch self.read {
    case true:
      "m[\(hex: self.address)] -> \(hex: self.value, bits: self.bits)"
    case false:
      "m[\(hex: self.address)] <- \(hex: self.value, bits: self.bits)"
    }
  }
}
