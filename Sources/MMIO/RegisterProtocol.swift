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

/// A protocol defining the common initialization interface for Memory-Mapped
/// I/O entities.
///
/// This protocol is adopted by ``MMIO/Register`` and `struct`s  annotated with
/// the ``RegisterBlock()`` macro. It ensures that types representing a block of
/// registers (a peripheral or a sub-block) can be initialized with a base
/// memory address and, optionally, an ``MMIO/MMIOInterposer`` for testing
/// purposes.
///
/// The main use of `RegisterProtocol` is to enable generic handling of register
/// blocks, particularly within ``RegisterArray`` when it stores an array of
/// register blocks rather than individual registers.
///
/// - Note: You typically do not interact with this protocol directly or
///   conform types to it manually. Conformance is automatically provided by the
///   ``RegisterBlock()`` macro.
public protocol RegisterProtocol {
  #if FEATURE_INTERPOSABLE
  /// Initializes a new instance of the MMIO entity.
  ///
  /// This initializer is used when the `FEATURE_INTERPOSABLE` flag is enabled
  /// during compilation, allowing an ``MMIO/MMIOInterposer`` to be provided for
  /// testing.
  ///
  /// - Parameters:
  ///   - unsafeAddress: The base memory address for this entity.
  ///   - interposer: An optional ``MMIOInterposer`` to intercept
  ///     memory accesses. If `nil`, accesses go directly to hardware.
  init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?)
  #else
  /// Initializes a new instance of the MMIO entity.
  ///
  /// - Parameter unsafeAddress: The base memory address for this entity.
  init(unsafeAddress: UInt)
  #endif
}
