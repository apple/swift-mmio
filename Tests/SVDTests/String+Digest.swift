//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if canImport(CryptoKit)
import CryptoKit
import Foundation

extension String {
  init<D: Digest>(_ digest: D) {
    let digits = D.byteCount * 2

    self.init(unsafeUninitializedCapacity: digits) { utf8Buffer in
      var utf8BufferIndex = 0
      unsafe digest.withUnsafeBytes { digestBuffer in
        func appendNibble(_ nibble: UInt8) {
          let ascii =
            switch nibble {
            case 0..<10:
              UInt8(ascii: "0") + UInt8(nibble)
            case 10..<16:
              UInt8(ascii: "a") + UInt8(nibble - 10)
            default:
              preconditionFailure("Invalid hexadecimal digit \(nibble)")
            }
          unsafe utf8Buffer[utf8BufferIndex] = ascii
          utf8BufferIndex += 1
        }

        for unsafe byte in unsafe digestBuffer {
          appendNibble((byte >> 4) & 0xf)
          appendNibble((byte >> 0) & 0xf)
        }
      }
      return utf8BufferIndex
    }
  }
}
#endif
