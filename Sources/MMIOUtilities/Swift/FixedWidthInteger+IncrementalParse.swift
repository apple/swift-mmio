//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension FixedWidthInteger {
  public mutating func incrementalParseAppend(
    digit: Self,
    base: Self
  ) -> Bool {
    let multiply = self.multipliedReportingOverflow(by: base)
    guard !multiply.overflow else { return false }
    let add = multiply.partialValue.addingReportingOverflow(digit)
    guard !add.overflow else { return false }
    self = add.partialValue
    return true
  }
}
