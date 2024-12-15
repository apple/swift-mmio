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

import CryptoKit

extension Digest {
  // This is not production quality code. This is strictly test support code.
  func equals(_ hexString: String) -> Bool {
    withUnsafeTemporaryAllocation(
      byteCount: Self.byteCount,
      alignment: MemoryLayout<UInt8>.alignment
    ) { expected in
      precondition(hexString.utf8.count == Self.byteCount * 2)
      var hexString = hexString
      var index = 0
      while !hexString.isEmpty {
        let hexByte = hexString.prefix(2)
        hexString.removeFirst(2)
        let byte = UInt8(hexByte, radix: 16)!
        expected[index] = byte
        index += 1
      }
      return self.withUnsafeBytes { actual in
        actual.elementsEqual(expected)
      }
    }
  }
}
