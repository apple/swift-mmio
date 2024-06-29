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

extension SVDRegisterProperties {
  public static let none = SVDRegisterProperties(
    size: nil,
    access: nil,
    protection: nil,
    resetValue: nil,
    resetMask: nil)

  public func merging(_ other: Self) -> Self {
    SVDRegisterProperties(
      size: self.size ?? other.size,
      access: self.access ?? other.access,
      protection: self.protection ?? other.protection,
      resetValue: self.resetValue ?? other.resetValue,
      resetMask: self.resetMask ?? other.resetMask)
  }
}
