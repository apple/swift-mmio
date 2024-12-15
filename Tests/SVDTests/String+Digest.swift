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

extension String {
  init<D: Digest>(_ digest: D) {
    let digits = D.byteCount * 2

    self.init(unsafeUninitializedCapacity: digits) { utf8Buffer in
      var utf8BufferIndex = 0
      digest.withUnsafeBytes { digestBuffer in
        func appendNibble(_ nibble: UInt8) {
          let ascii = switch nibble {
            case 0..<10:
              UInt8(ascii: "0") + UInt8(nibble)
            case 10..<16:
              UInt8(ascii: "a") + UInt8(nibble - 10)
            default:
              preconditionFailure("Invalid hexadecimal digit \(nibble)")
            }
          utf8Buffer[utf8BufferIndex] = ascii
          utf8BufferIndex += 1
        }

        for byte in digestBuffer {
          appendNibble((byte >> 4) & 0xf)
          appendNibble((byte >> 0) & 0xf)
        }
      }
      return utf8BufferIndex
    }
  }

//  // This is not production quality code. This is strictly test support code.
//  func equals(_ hexString: String) -> Bool {
//    withUnsafeTemporaryAllocation(
//      byteCount: Self.byteCount,
//      alignment: MemoryLayout<UInt8>.alignment
//    ) { expected in
//      precondition(hexString.utf8.count == Self.byteCount * 2)
//
//      var inputIndex = hexString.utf8.startIndex
//      var outputIndex = 0
//      while inputIndex < hexString.utf8.endIndex {
//        var byte: UInt8 = 0
//        for _ in 0..<2 {
//          byte = (byte << 4) | hexString.utf8[inputIndex]
//          hexString.utf8.formIndex(after: &inputIndex)
//        }
//        expected[outputIndex] = byte
//        outputIndex += 1
//      }
//      return self.withUnsafeBytes { actual in
//        actual.elementsEqual(expected)
//      }
//    }
//  }
}
