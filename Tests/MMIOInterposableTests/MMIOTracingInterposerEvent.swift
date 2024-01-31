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

struct MMIOTracingInterposerEvent {
  var load: Bool
  var address: UInt
  var size: Int
  var value: UInt64
}

extension MMIOTracingInterposerEvent {
  static func load<Value>(
    of value: Value,
    from address: UInt
  ) -> Self where Value: FixedWidthInteger & UnsignedInteger {
    Self(
      load: true,
      address: address,
      size: MemoryLayout<Value>.size * 8,
      value: UInt64(value))
  }

  static func store<Value>(
    of value: Value,
    to address: UInt
  ) -> Self where Value: FixedWidthInteger & UnsignedInteger {
    Self(
      load: false,
      address: address,
      size: MemoryLayout<Value>.size * 8,
      value: UInt64(value))
  }
}

extension MMIOTracingInterposerEvent: Equatable {}

extension MMIOTracingInterposerEvent: CustomStringConvertible {
  var description: String {
    switch self.load {
    case true:
      "m[\(hex: self.address)] -> \(hex: self.value, bits: self.size)"
    case false:
      "m[\(hex: self.address)] <- \(hex: self.value, bits: self.size)"
    }
  }
}
