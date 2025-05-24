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


/// A protocol for types that can intercept memory-mapped I/O (MMIO) register operations.
///
/// `MMIOInterposer` instances are primarily used for unit testing code that
/// interacts with MMIO registers, allowing tests to run without actual hardware.
/// By providing a custom interposer when initializing a ``RegisterBlock`` or
/// ``Register``, you can simulate hardware responses, trace register accesses,
/// or inject specific values for register reads.
///
/// An interposer acts as a proxy for memory accesses. Instead of direct hardware
/// interaction, ``Register`` operations are redirected to the interposer's
/// `load(from:)` and `store(_:to:)` methods. This enables:
/// - **Hardware Simulation:** Mimic register behavior, such as returning predefined
///   values or simulating state changes upon writes.
/// - **Access Tracing:** Record a sequence of register reads and writes for later
///   verification in tests.
/// - **Fault Injection:** Simulate error conditions or unexpected hardware states.
///
/// ## Conforming to MMIOInterposer
/// To create a custom interposer, define a class that conforms to this protocol
/// and implement the required `load` and `store` methods. These methods
/// receive the memory pointer (address) and, for stores, the value being written,
/// allowing your interposer to react accordingly.
///
/// - Note: This protocol and its associated functionality are only available if
///   the `MMIO` package is compiled with the `FEATURE_INTERPOSABLE` Swift flag
///   (e.g., by passing `-Xswiftc -DFEATURE_INTERPOSABLE` during compilation).
///   This is typically done for test builds. For non-interposable builds, MMIO
///   accesses interact directly with hardware memory.
///
/// For a detailed guide on using interposers in your testing workflow, see
/// <doc:Testing-With-Interposers>.
public protocol MMIOInterposer: AnyObject {
  /// Intercepts a register read (load) operation.
  ///
  /// This method is called by ``Register/read()`` or during the read phase of
  /// ``Register/modify(_:)`` when an interposer is active for that ``Register``
  /// instance.
  ///
  /// Your implementation should simulate the hardware read. This might involve:
  /// - Returning a value from a dictionary or other structure that models the
  ///   register space.
  /// - Logging the access for later verification.
  /// - Returning a dynamically calculated value based on a simulated state.
  ///
  /// - Parameter pointer: An `UnsafePointer` to the memory location (register
  ///   address) from which the load was originally intended. The type `Value`
  ///   indicates the underlying storage type of the register (e.g., `UInt32`).
  /// - Returns: A `Value` representing the data that simulates a load from the
  ///   specified register address.
  func load<Value>(
    from pointer: UnsafePointer<Value>
  ) -> Value where Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage

  /// Intercepts a register write (store) operation.
  ///
  /// This method is called by ``Register/write(_:)`` or during the write phase of
  /// ``Register/modify(_:)`` when an interposer is active for that ``Register``
  /// instance.
  ///
  /// Your implementation should simulate the hardware write. This could involve:
  /// - Storing the `value` in a test-specific memory model (e.g., a dictionary
  ///   mapping addresses to values).
  /// - Recording the write operation (address and value) for later assertion in tests.
  /// - Simulating side effects that the write would cause in actual hardware.
  ///
  /// - Parameters:
  ///   - value: The `Value` (e.g., `UInt32` being written to the register.
  ///   - pointer: An `UnsafeMutablePointer` to the memory location
  ///     (register address) to which the store was originally intended. The type
  ///     `Value` indicates the underlying storage type of the register.
  func store<Value>(
    _ value: Value,
    to pointer: UnsafeMutablePointer<Value>
  ) where Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage
}

