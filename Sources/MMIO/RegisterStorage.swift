//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import MMIOVolatile

/// A type that represents the storage of a register value type.
///
/// The set of types which conform to this protocol is restricted to the set of
/// volatile operations available on the platform. As such, user code must
/// _never_ conform new types to this protocol.
public protocol _RegisterStorage {
  /// Loads an instance of `self` from the address pointed to by pointer.
  static func load(from pointer: UnsafePointer<Self>) -> Self
  /// Stores an instance of `self` to the address pointed to by pointer.
  static func store(_ value: Self, to pointer: UnsafeMutablePointer<Self>)
}

extension UInt8: _RegisterStorage {
  /// Loads an instance of `self` from the address pointed to by pointer.
  @inlinable @inline(__always)
  public static func load(from pointer: UnsafePointer<Self>) -> Self {
    mmio_volatile_load_uint8_t(pointer)
  }

  /// Stores an instance of `self` to the address pointed to by pointer.
  @inlinable @inline(__always)
  public static func store(
    _ value: Self,
    to pointer: UnsafeMutablePointer<Self>
  ) {
    mmio_volatile_store_uint8_t(pointer, value)
  }
}

extension UInt16: _RegisterStorage {
  /// Loads an instance of `self` from the address pointed to by pointer.
  @inlinable @inline(__always)
  public static func load(from pointer: UnsafePointer<Self>) -> Self {
    mmio_volatile_load_uint16_t(pointer)
  }

  /// Stores an instance of `self` to the address pointed to by pointer.
  @inlinable @inline(__always)
  public static func store(
    _ value: Self,
    to pointer: UnsafeMutablePointer<Self>
  ) {
    mmio_volatile_store_uint16_t(pointer, value)
  }
}

extension UInt32: _RegisterStorage {
  /// Loads an instance of `self` from the address pointed to by pointer.
  @inlinable @inline(__always)
  public static func load(from pointer: UnsafePointer<Self>) -> Self {
    mmio_volatile_load_uint32_t(pointer)
  }

  /// Stores an instance of `self` to the address pointed to by pointer.
  @inlinable @inline(__always)
  public static func store(
    _ value: Self,
    to pointer: UnsafeMutablePointer<Self>
  ) {
    mmio_volatile_store_uint32_t(pointer, value)
  }
}

#if arch(x86_64) || arch(arm64)
extension UInt64: _RegisterStorage {
  /// Loads an instance of `self` from the address pointed to by pointer.
  @inlinable @inline(__always)
  public static func load(from pointer: UnsafePointer<Self>) -> Self {
    mmio_volatile_load_uint64_t(pointer)
  }

  /// Stores an instance of `self` to the address pointed to by pointer.
  @inlinable @inline(__always)
  public static func store(
    _ value: Self,
    to pointer: UnsafeMutablePointer<Self>
  ) {
    mmio_volatile_store_uint64_t(pointer, value)
  }
}
#endif
