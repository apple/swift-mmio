//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Describe the manipulation of data written to a field.
public enum SVDModifiedWriteValues: String {
  /// Write data bit of one shall clear (set to zero) the corresponding bit in
  /// the field.
  case oneToClear
  /// Write data bit of one shall set (set to one) the corresponding bit in
  /// the field.
  case oneToSet
  /// Write data bit of one shall toggle (invert) the corresponding bit in the
  /// field.
  case oneToToggle
  /// Write data bit of zero shall clear (set to zero) the corresponding bit
  /// in the field.
  case zeroToClear
  /// Write data bit of zero shall set (set to one) the corresponding bit in
  /// the field.
  case zeroToSet
  /// Write data bit of zero shall toggle (invert) the corresponding bit in
  /// the field.
  case zeroToToggle
  /// After a write operation all bits in the field are cleared (set to zero).
  case clear
  /// After a write operation all bits in the field are set (set to one).
  case set
  /// After a write operation all bits in the field may be modified (default).
  case modify
}

extension SVDModifiedWriteValues: Decodable {}

extension SVDModifiedWriteValues: Encodable {}

extension SVDModifiedWriteValues: Equatable {}

extension SVDModifiedWriteValues: Hashable {}

extension SVDModifiedWriteValues: Sendable {}

extension SVDModifiedWriteValues: XMLNodeInitializable {}
