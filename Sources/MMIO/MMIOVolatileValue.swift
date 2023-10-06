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

/// A type that supports volatile operations through a separate volatile storage
/// representation.
public protocol MMIOVolatileValue {
  // FIXME: Remove need for MMIOVolatileRepresentation with compiler support
  // All types can be MMIOVolatileValues if they are bitwise copyable and have a
  // bit width which maps to platform intrinsic load/store width. This could be
  // represented with the following potential future swift.
  // extension<Type> Type: MMIOVolatileValue where Type: BitwiseCopyable, MemoryLayout<Type>.size == 1 { }
  // extension<Type> Type: MMIOVolatileValue where Type: BitwiseCopyable, MemoryLayout<Type>.size == 2 { }
  // extension<Type> Type: MMIOVolatileValue where Type: BitwiseCopyable, MemoryLayout<Type>.size == 4 { }
  // extension<Type> Type: MMIOVolatileValue where Type: BitwiseCopyable, MemoryLayout<Type>.size == 8 { }

  /// The volatile storage representation for this value.
  associatedtype MMIOVolatileRepresentation: MMIOVolatileStorage
  /* where Self.bitWidth == MMIOVolatileRepresentation.bitWidth */
}

extension MMIOVolatileValue {
  /// Loads an instance of `self` from the address pointed to by pointer.
  ///
  /// First loads Self.MMIOVolatileRepresentation from the pointer, then
  /// reinterprets the bits as Self.
  @_transparent
  static func load(from pointer: UnsafePointer<Self>) -> Self {
    pointer.withMemoryRebound(
      to: Self.MMIOVolatileRepresentation.self,
      capacity: 1
    ) { pointer in
      let value = Self.MMIOVolatileRepresentation.load(from: pointer)
      return unsafeBitCast(value, to: Self.self)
    }
  }

  /// Stores an instance of `self` to the address pointed to by pointer.
  ///
  /// First reinterprets the bits of Self as Self.MMIOVolatileRepresentation,
  /// then stores the bits to the pointer.
  @_transparent
  static func store(_ value: Self, to pointer: UnsafeMutablePointer<Self>) {
    pointer.withMemoryRebound(
      to: MMIOVolatileRepresentation.self,
      capacity: 1
    ) { pointer in
      let value = unsafeBitCast(
        value,
        to: MMIOVolatileRepresentation.self
      )
      Self.MMIOVolatileRepresentation.store(value, to: pointer)
    }
  }
}

extension UInt8: MMIOVolatileValue {
  /// The volatile storage representation for this value.
  public typealias MMIOVolatileRepresentation = UInt8
}

extension UInt16: MMIOVolatileValue {
  /// The volatile storage representation for this value.
  public typealias MMIOVolatileRepresentation = UInt16
}

extension UInt32: MMIOVolatileValue {
  /// The volatile storage representation for this value.
  public typealias MMIOVolatileRepresentation = UInt32
}

#if arch(x86_64) || arch(arm64)
  extension UInt64: MMIOVolatileValue {
    /// The volatile storage representation for this value.
    public typealias MMIOVolatileRepresentation = UInt64
  }
#endif

extension Int8: MMIOVolatileValue {
  /// The volatile storage representation for this value.
  public typealias MMIOVolatileRepresentation = UInt8
}

extension Int16: MMIOVolatileValue {
  /// The volatile storage representation for this value.
  public typealias MMIOVolatileRepresentation = UInt16
}

extension Int32: MMIOVolatileValue {
  /// The volatile storage representation for this value.
  public typealias MMIOVolatileRepresentation = UInt32
}

#if arch(x86_64) || arch(arm64)
  extension Int64: MMIOVolatileValue {
    /// The volatile storage representation for this value.
    public typealias MMIOVolatileRepresentation = UInt64
  }
#endif
