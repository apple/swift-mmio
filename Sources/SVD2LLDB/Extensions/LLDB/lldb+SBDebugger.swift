//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import LLDB
import MMIOUtilities

extension lldb.SBDebugger: SVD2LLDBDebugger {
  mutating func read(
    address: UInt64,
    bits: some FixedWidthInteger
  ) throws -> UInt64 {
    var value: UInt64 = 0
    var error = lldb.SBError()
    let bytes = bits.roundUp(toMultipleOf: 8) / 8
    precondition(bytes <= MemoryLayout.size(ofValue: value))
    var target = self.GetSelectedTarget()
    var process = target.GetProcess()
    let count = process.ReadMemory(address, &value, Int(bytes), &error)
    if count != bytes {
      error.SetError(5 /* EIO */, lldb.eErrorTypePOSIX)
      throw error
    }
    if error.IsValid() {
      throw error
    }
    return value
  }

  mutating func write(
    address: UInt64,
    value: UInt64,
    bits: some FixedWidthInteger
  ) throws {
    var value = value
    var error = lldb.SBError()
    let bytes = bits.roundUp(toMultipleOf: 8) / 8
    precondition(bytes <= MemoryLayout.size(ofValue: value))
    var target = self.GetSelectedTarget()
    var process = target.GetProcess()
    let count = process.WriteMemory(address, &value, Int(bytes), &error)
    if count != bytes {
      error.SetError(5 /* EIO */, lldb.eErrorTypePOSIX)
      throw error
    }
    if error.IsValid() {
      throw error
    }
  }
}
