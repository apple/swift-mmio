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

/// A protocol identifying types suitable for underlying register storage and
/// capable of performing volatile memory operations.
///
/// `_RegisterStorage` is an internal protocol within Swift MMIO. It restricts
/// the set of types that can serve as the raw storage for a memory-mapped
/// register to those for which volatile load and store operations are
/// explicitly provided. This ensures that all hardware interactions maintain
/// correct volatile memory semantics, preventing unintended compiler
/// optimizations.
///
/// The conforming types are `UInt8`, `UInt16`, `UInt32`, and `UInt64`. These
/// correspond to the fixed-width integer types for which the `MMIOVolatile`
/// C module provides volatile access functions.
///
/// This protocol constrains the `Storage` associated type within
/// ``RegisterValueRaw``, forming a critical part of Swift MMIO's safety
/// mechanism for hardware interaction.
///
/// - Warning: This is an internal protocol. Do not attempt to conform new types
///   to `_RegisterStorage`.
///
/// See <doc:Volatile-Access>, for more background.
public protocol _RegisterStorage {
  /// Performs a volatile load of an instance of `Self` from the memory address
  /// pointed to by `pointer`.
  ///
  /// This operation guarantees that the read is not optimized away by the
  /// compiler and directly accesses the hardware memory location.
  ///
  /// - Parameter pointer: An `UnsafePointer` to the memory location (register
  ///   address) from which to read.
  ///
  /// - Returns: The value read from the memory location.
  static func load(from pointer: UnsafePointer<Self>) -> Self

  /// Performs a volatile store of `value` to the memory address pointed to by
  /// `pointer`.
  ///
  /// This operation guarantees that the write is not optimized away by the
  /// compiler and directly modifies the hardware memory location.
  ///
  /// - Parameter value: The value to write to the memory location.
  /// - Parameter pointer: An `UnsafePointer` to the memory location (register
  ///   address) to write to.
  static func store(_ value: Self, to pointer: UnsafeMutablePointer<Self>)
}

extension UInt8: _RegisterStorage {
  /// Performs a volatile load of a `UInt8` value from the specified memory
  /// address.
  @inlinable @inline(__always)
  public static func load(from pointer: UnsafePointer<Self>) -> Self {
    mmio_volatile_load_uint8_t(pointer)
  }

  /// Performs a volatile store of a `UInt8` value to the specified memory
  /// address.
  @inlinable @inline(__always)
  public static func store(
    _ value: Self,
    to pointer: UnsafeMutablePointer<Self>
  ) {
    mmio_volatile_store_uint8_t(pointer, value)
  }
}

extension UInt16: _RegisterStorage {
  /// Performs a volatile load of a `UInt16` value from the specified memory
  /// address.
  @inlinable @inline(__always)
  public static func load(from pointer: UnsafePointer<Self>) -> Self {
    mmio_volatile_load_uint16_t(pointer)
  }

  /// Performs a volatile store of a `UInt16` value to the specified memory
  /// address.
  @inlinable @inline(__always)
  public static func store(
    _ value: Self,
    to pointer: UnsafeMutablePointer<Self>
  ) {
    mmio_volatile_store_uint16_t(pointer, value)
  }
}

extension UInt32: _RegisterStorage {
  /// Performs a volatile load of a `UInt32` value from the specified memory
  /// address.
  @inlinable @inline(__always)
  public static func load(from pointer: UnsafePointer<Self>) -> Self {
    mmio_volatile_load_uint32_t(pointer)
  }

  /// Performs a volatile store of a `UInt32` value to the specified memory
  /// address.
  @inlinable @inline(__always)
  public static func store(
    _ value: Self,
    to pointer: UnsafeMutablePointer<Self>
  ) {
    mmio_volatile_store_uint32_t(pointer, value)
  }
}

#if arch(x86_64) || arch(arm64)
// `UInt64` operations are typically available on 64-bit architectures.
extension UInt64: _RegisterStorage {
  /// Performs a volatile load of a `UInt64` value from the specified memory
  /// address.
  @inlinable @inline(__always)
  public static func load(from pointer: UnsafePointer<Self>) -> Self {
    mmio_volatile_load_uint64_t(pointer)
  }

  /// Performs a volatile store of a `UInt64` value to the specified memory
  /// address.
  @inlinable @inline(__always)
  public static func store(
    _ value: Self,
    to pointer: UnsafeMutablePointer<Self>
  ) {
    mmio_volatile_store_uint64_t(pointer, value)
  }
}
#endif
