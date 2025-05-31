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

/// A type representing an array of memory-mapped registers or register blocks.
///
/// `RegisterArray` provides a structured and convenient way to define and
/// access repetitive hardware elements, such as a series of identical DMA
/// channels, GPIO port configuration registers, or communication mailboxes.
/// Elements within the array are accessed using a standard integer subscript.
/// Each access automatically calculates the correct memory address for the
/// specific element based on the array's base address, the element index, and
/// the defined stride.
///
/// - Parameter Value: The type of the elements in the array. This can be:
///   - A `struct` conforming to ``RegisterValue`` (typically defined with the
///     ``MMIO/Register(bitWidth:)`` macro), if the array consists of individual
///     registers.
///   - A `struct` conforming to ``RegisterProtocol`` (typically defined with
///     the ``RegisterBlock()`` macro), if the array consists of groups of
///     registers (register blocks).
///
/// ## Topics
///
/// ### Initializing a Register Array
/// - ``init(unsafeAddress:stride:count:)``
/// - ``init(unsafeAddress:stride:count:interposer:)``
///
/// ### Accessing Elements
/// - ``subscript(_:)->Value``
/// - ``subscript(_:)->Register<Value>``
///
/// ### Unsafe Properties
/// - ``unsafeAddress``
/// - ``stride``
/// - ``count``
/// - ``interposer``
public struct RegisterArray<Value> {
  /// The base memory address of the first element in this array.
  public var unsafeAddress: UInt

  /// The byte distance between the start of one element and the start of the
  /// next.
  public var stride: UInt

  /// The total number of elements in this array.
  public var count: UInt

  #if FEATURE_INTERPOSABLE
  /// An optional interposer instance, propagated to elements accessed through
  /// this array.
  ///
  /// - Note: This property is only available if the `MMIO` package is compiled
  ///   with the `FEATURE_INTERPOSABLE` Swift flag.
  public var interposer: (any MMIOInterposer)?
  #endif

  #if FEATURE_INTERPOSABLE
  /// Initializes a new register array with an optional interposer.
  ///
  /// - Precondition:
  ///   - `unsafeAddress` must point to the beginning of a valid hardware
  ///     register array as per the device's memory map.
  ///   - `stride` must accurately reflect the hardware layout. For example, if
  ///     registers are 4 bytes each and contiguous, stride is 4; if they are 4
  ///     bytes each but located every 16 bytes, stride is 16.
  ///   - `count` must not exceed the actual number of hardware elements in the
  ///     array.
  ///
  /// - Parameters:
  ///   - unsafeAddress: The absolute memory address of the first element in the
  ///     array.
  ///   - stride: The number of bytes from the start of one element to the start
  ///     of the next (the step between elements).
  ///   - count: The total number of elements in the array.
  ///   - interposer: An optional ``MMIO/MMIOInterposer`` for intercepting
  ///     memory accesses, primarily for testing.
  @inlinable @inline(__always)
  public init(
    unsafeAddress: UInt,
    stride: UInt,
    count: UInt,
    interposer: (any MMIOInterposer)?
  ) {
    self.unsafeAddress = unsafeAddress
    self.stride = stride
    self.count = count
    self.interposer = interposer
  }
  #else
  /// Initializes a new register array.
  ///
  /// - Precondition:
  ///   - `unsafeAddress` must point to the beginning of a valid hardware
  ///     register array as per the device's memory map.
  ///   - `stride` must accurately reflect the hardware layout. For example, if
  ///     registers are 4 bytes each and contiguous, stride is 4; if they are 4
  ///     bytes each but located every 16 bytes, stride is 16.
  ///   - `count` must not exceed the actual number of hardware elements in the
  ///     array.
  ///
  /// - Parameters:
  ///   - unsafeAddress: The absolute memory address of the first element in the
  ///     array.
  ///   - stride: The number of bytes from the start of one element to the start
  ///     of the next (the step between elements).
  ///   - count: The total number of elements in the array.
  @inlinable @inline(__always)
  public init(
    unsafeAddress: UInt,
    stride: UInt,
    count: UInt
  ) {
    self.unsafeAddress = unsafeAddress
    self.stride = stride
    self.count = count
  }
  #endif
}

extension RegisterArray where Value: RegisterValue {
  /// Accesses the register at the specified `index` within the array.
  ///
  /// - Precondition: `index` must be a valid index within the bounds
  ///   `0..<self.count`. Accessing an out-of-bounds index triggers a runtime
  ///   trap.
  ///
  /// - Parameter index: A zero-based integer index indicating the position of
  ///   the desired register in the array.
  ///
  /// - Returns: A ``MMIO/Register`` instance configured to access the hardware
  ///   register at the calculated address:
  ///   `self.unsafeAddress + (UInt(index) * self.stride)`.
  @inlinable @inline(__always)
  public subscript<Index>(
    _ index: Index
  ) -> Register<Value> where Index: BinaryInteger {
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      0 <= index && index < self.count,
      "Index out of bounds")
    #else
    precondition(
      0 <= index && index < self.count,
      "Index '\(index)' out of bounds '0..<\(self.count)'")
    #endif
    let elementAddress = self.unsafeAddress + (UInt(index) * self.stride)
    #if FEATURE_INTERPOSABLE
    return .init(
      unsafeAddress: elementAddress,
      interposer: self.interposer)
    #else
    return .init(unsafeAddress: elementAddress)
    #endif
  }
}

extension RegisterArray where Value: RegisterProtocol {
  /// Accesses the register block at the specified `index` within the array.
  ///
  /// - Precondition: `index` must be a valid index within the bounds
  ///   `0..<self.count`. Accessing an out-of-bounds index triggers a runtime
  ///   trap.
  ///
  /// - Parameter index: A zero-based integer index indicating the position of
  ///   the desired register block in the array.
  ///
  /// - Returns: An instance of `Value` (the register block type) configured to
  ///   access the hardware block at the calculated address:
  ///   `self.unsafeAddress + (UInt(index) * self.stride)`.
  @inlinable @inline(__always)
  public subscript<Index>(
    _ index: Index
  ) -> Value where Index: BinaryInteger {
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      0 <= index && index < self.count,
      "Index out of bounds")
    #else
    precondition(
      0 <= index && index < self.count,
      "Index '\(index)' out of bounds '0..<\(self.count)'")
    #endif
    let elementAddress = self.unsafeAddress + (UInt(index) * self.stride)
    #if FEATURE_INTERPOSABLE
    return .init(
      unsafeAddress: elementAddress,
      interposer: self.interposer)
    #else
    return .init(unsafeAddress: elementAddress)
    #endif
  }
}
