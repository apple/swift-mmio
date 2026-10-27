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

extension UInt8 {
  /// A Boolean value that indicates whether the byte is an ASCII horizontal
  /// tab, newline, vertical tab, form feed, carriage return, or space.
  public var isWhiteSpace: Bool {
    switch self {
    case 0x09...0x0d, 0x20: true
    default: false
    }
  }
}
