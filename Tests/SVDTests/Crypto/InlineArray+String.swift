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

@available(macOS 9999, *)
extension InlineArray: @retroactive ExpressibleByUnicodeScalarLiteral where Element == UInt8 { }

@available(macOS 9999, *)
extension InlineArray: @retroactive ExpressibleByExtendedGraphemeClusterLiteral where Element == UInt8 { }

@available(macOS 9999, *)
extension InlineArray: @retroactive ExpressibleByStringLiteral where Element == UInt8 {
  public typealias StringLiteralType = String

  public init(stringLiteral literal: String) {
    precondition(literal.utf8.count == Self.count)
    self.init(repeating: 0)
    var index = 0
    for byte in literal.utf8 {
      self[index] = byte
      index += 1
    }
  }
}

@available(macOS 9999, *)
extension String {
  private static let hexDigits: InlineArray<16, UInt8> = "0123456789abcdef"

  init(hex bytes: RawSpan) {
    let byteCount = bytes.byteCount * 2
    self.init(unsafeUninitializedCapacity: byteCount) { outBuffer in
      bytes.withUnsafeBytes { inBuffer in
        var index = 0
        for byte in inBuffer {
          outBuffer[index] = Self.hexDigits[Int(byte >> 4)]
          index += 1
          outBuffer[index] = Self.hexDigits[Int(byte & 0xf)]
          index += 1
        }
      }
      return byteCount
    }
  }
}
