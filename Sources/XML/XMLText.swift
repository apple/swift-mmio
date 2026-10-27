//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// The UTF-8 text of an element or of an attribute value.
///
/// The bytes are valid only during the call that receives the text.
public struct XMLText {
  public var bytes: UnsafeBufferPointer<UInt8>

  @inlinable
  public init(bytes: UnsafeBufferPointer<UInt8>) {
    self.bytes = bytes
  }
}

extension String {
  @inlinable
  public init(_ text: XMLText) {
    self = String(decoding: text.bytes, as: UTF8.self)
  }
}

/// The UTF-8 name of an element or of an attribute.
///
/// The bytes are valid only during the call that receives the name.
public struct XMLName {
  public var bytes: UnsafeBufferPointer<UInt8>

  @inlinable
  public init(bytes: UnsafeBufferPointer<UInt8>) {
    self.bytes = bytes
  }

  /// Returns a Boolean value that indicates whether the name is equal to a
  /// string literal.
  @inlinable
  public static func ~= (pattern: StaticString, name: XMLName) -> Bool {
    let pattern = UnsafeBufferPointer(
      start: pattern.utf8Start, count: pattern.utf8CodeUnitCount)
    return name.bytes.elementsEqual(pattern)
  }
}
