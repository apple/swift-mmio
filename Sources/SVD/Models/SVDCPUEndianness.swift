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

public import XML

public enum SVDCPUEndianness: String {
  /// Little endian memory (least significant byte gets allocated at the
  /// lowest address).
  case little
  /// Byte invariant big endian data organization (most significant byte gets
  /// allocated at the lowest address).
  case big
  /// Little and big endian are configurable for the device and become active
  /// after the next reset.
  case selectable
  /// The endianness is neither little nor big endian.
  case other
}

extension SVDCPUEndianness: Decodable {}

extension SVDCPUEndianness: Encodable {}

extension SVDCPUEndianness: Equatable {}

extension SVDCPUEndianness: Hashable {}

extension SVDCPUEndianness: Sendable {}

extension SVDCPUEndianness: XMLElementInitializable {}
