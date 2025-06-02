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

/// A protocol for intercepting memory-mapped I/O operations.
///
/// `MMIOInterposer` enables testing of MMIO-based code without physical
/// hardware by intercepting register reads and writes. When provided to a
/// ``MMIO/Register`` it redirects memory operations to the interposer's
/// methods.
///
/// For usage details, see <doc:Testing-With-Interposers>.
#if !FEATURE_INTERPOSABLE
@available(
  *, deprecated, message: "Define FEATURE_INTERPOSABLE to enable interposers."
)
#endif
public protocol MMIOInterposer: AnyObject {
  /// Intercepts a register read operation.
  ///
  /// Called when a register with this interposer is read via
  /// ``MMIO/Register/read()`` or during the read phase of
  /// ``MMIO/Register/modify(_:)``.
  ///
  /// - Parameter pointer: A pointer to the register's memory address.
  ///
  /// - Returns: The value to simulate reading from hardware.
  func load<Value>(
    from pointer: UnsafePointer<Value>
  ) -> Value where Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage

  /// Intercepts a register write operation.
  ///
  /// Called when a value is written to a register with this interposer via
  /// ``MMIO/Register/write(_:)`` or during the write phase of
  /// ``MMIO/Register/modify(_:)``.
  ///
  /// - Parameters:
  ///   - value: The value being written.
  ///   - pointer: A pointer to the register's memory address.
  func store<Value>(
    _ value: Value,
    to pointer: UnsafeMutablePointer<Value>
  ) where Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage
}
