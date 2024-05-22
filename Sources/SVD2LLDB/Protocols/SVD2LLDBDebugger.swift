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

protocol SVD2LLDBDebugger {
  // FIXME: Replace UInt64 with UInt128
  mutating func read(
    address: UInt64,
    bits: some FixedWidthInteger
  ) throws -> UInt64
  mutating func write(
    address: UInt64,
    value: UInt64,
    bits: some FixedWidthInteger
  ) throws
}
