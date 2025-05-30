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

/// A type that provides access to a hardware memory-mapped register.
///
/// `Register` is the primary mechanism for interacting with a hardware register
/// whose layout and bit fields are defined by its `Value` type (which conforms
/// to ``RegisterValue``). It abstracts the details of volatile memory access
/// and offers methods for reading, writing, and modifying the register's
/// contents in a type-safe manner.
///
/// ```swift
/// // Create a register instance at a specific memory address
/// let statusRegister = DeviceStatus(unsafeAddress: 0x40000000)
///
/// // Read the current value
/// let status = statusRegister.read()
/// if status.enableFlag {
///     // Handle enabled state
/// }
///
/// // Write a new value
/// statusRegister.write { value in
///     value.enableFlag = true
///     value.mode = .normal
/// }
/// ```
///
/// All register accesses through Swift MMIO use volatile semantics to ensure
/// correct interaction with hardware. See <doc:Volatile-Access> for more
/// details.
///
/// ## Topics
///
/// ### Initializing a Register
///
/// - ``init(unsafeAddress:)``
/// - ``init(unsafeAddress:interposer:)``
///
/// ### Accessing Register Contents
///
/// - ``read()``
/// - ``write(_:)->()``
/// - ``write(_:)->_``
/// - ``modify(_:)-((Value.Read,Value.Write)->(T))``
/// - ``modify(_:)``
///
/// ### Unsafe Properties
///
/// - ``unsafeAddress``
/// - ``interposer``
///
/// - Parameter Value: A `struct`, typically defined using the 
///   ``MMIO/Register(bitWidth:)`` macro, that describes the bit-level layout of 
///   the hardware register.
public struct Register<Value>: RegisterProtocol where Value: RegisterValue {
  /// The absolute memory address of this register.
  ///
  /// This address is the target for all load and store operations performed by
  /// this `Register` instance. It must correctly point to the intended hardware 
  /// register as specified in the device's memory map or datasheet.
  ///
  /// ```swift
  /// let controlRegister = ControlRegister(unsafeAddress: 0x40000100)
  /// print(controlRegister.unsafeAddress) // prints "1073742080"
  /// ```
  ///
  /// - Warning: Providing an incorrect address can lead to undefined behavior,
  ///   data corruption, or system instability. Always verify addresses against
  ///   official hardware documentation. See <doc:Safety-Considerations>
  ///   for more details on safety.
  public var unsafeAddress: UInt

  #if FEATURE_INTERPOSABLE
  /// An optional interposer instance for intercepting memory accesses,
  /// primarily for testing.
  ///
  /// When an interposer is provided, all memory operations (reads and writes)
  /// are routed through it instead of directly accessing hardware memory. This
  /// allows for simulating hardware behavior, tracing register accesses, or
  /// providing fixed return values during unit tests.
  ///
  /// If this property is `nil` (the default for non-test builds or when not 
  /// specified), memory accesses performed by this `Register` instance interact 
  /// directly with hardware memory at `unsafeAddress`.
  ///
  /// > Note: This property is only available if the `MMIO` package is compiled
  ///   with the `FEATURE_INTERPOSABLE` Swift flag.
  public var interposer: (any MMIOInterposer)?
  #endif

  /// Internal check to ensure the register's memory address is correctly
  /// aligned.
  @inlinable @inline(__always)
  static func preconditionAligned(unsafeAddress: UInt) {
    let alignment = MemoryLayout<Value.Raw.Storage>.alignment
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      unsafeAddress.isMultiple(of: UInt(alignment)),
      "Misaligned address")
    #else
    precondition(
      unsafeAddress.isMultiple(of: UInt(alignment)),
      "Misaligned address '\(unsafeAddress)' for data of type '\(Value.self)'")
    #endif
  }

  #if FEATURE_INTERPOSABLE
  /// Initializes a register instance targeting a specific memory address,
  /// optionally with an interposer.
  ///
  /// - Parameters:
  ///   - unsafeAddress: The absolute memory address of the hardware register.
  ///   - interposer: An optional ``MMIOInterposer`` to route memory
  ///     accesses through, primarily used for testing purposes.
  ///
  /// - Precondition: `unsafeAddress` must be aligned to the natural alignment
  ///   of the register's underlying storage type.
  ///   alignment is for
  @inlinable @inline(__always)
  public init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?) {
    Self.preconditionAligned(unsafeAddress: unsafeAddress)
    self.unsafeAddress = unsafeAddress
    self.interposer = interposer
  }
  #else
  /// Initializes a register instance targeting a specific memory address.
  ///
  /// - Parameter unsafeAddress: The absolute memory address of the hardware
  ///   register.
  ///
  /// - Precondition: `unsafeAddress` must be aligned to the natural alignment
  ///   of the register's underlying storage type.
  ///   alignment is for
  @inlinable @inline(__always)
  public init(unsafeAddress: UInt) {
    Self.preconditionAligned(unsafeAddress: unsafeAddress)
    self.unsafeAddress = unsafeAddress
  }
  #endif
}

extension Register {
  /// A pointer to the memory location of the register.
  @inlinable @inline(__always)
  var pointer: UnsafeMutablePointer<Value.Raw.Storage> {
    // Unsafety is justified by the `unsafeAddress` initializer precondition
    // and the nature of MMIO.
    .init(bitPattern: self.unsafeAddress).unsafelyUnwrapped
  }

  /// Performs a volatile read from the register and returns a read view of
  /// its contents.
  ///
  /// This operation reads the current value from the hardware register at
  /// `unsafeAddress`. The `Value.Read` view provides typed access to the
  /// register's bit fields as defined in its `Value` type.
  ///
  /// ```swift
  /// // Read the current register state
  /// let status = statusRegister.read()
  ///
  /// // Access bit fields through the read view
  /// if status.powerEnabled {
  ///     print("Device is powered on")
  /// }
  /// ```
  ///
  /// All register accesses through Swift MMIO use volatile semantics to ensure
  /// correct interaction with hardware. See <doc:Volatile-Access> to learn
  /// more.
  ///
  /// - Returns: A `Value.Read` instance representing the current state of the 
  ///   register.
  @inlinable @inline(__always)
  public func read() -> Value.Read {
    let storage: Value.Raw.Storage
    #if FEATURE_INTERPOSABLE
    if let interposer = self.interposer {
      storage = interposer.load(from: self.pointer)
    } else {
      storage = Value.Raw.Storage.load(from: self.pointer)
    }
    #else
    storage = Value.Raw.Storage.load(from: self.pointer)
    #endif
    return Value.Read(Value.Raw(storage))
  }

  /// Performs a volatile write to the register using the provided `Write` view.
  ///
  /// This operation overwrites the entire register at `unsafeAddress` with the
  /// contents of `newValue`. The `Value.Write` view contains the data to be
  /// written, assembled according to the register's layout.
  ///
  /// ```swift
  /// // Create a write view
  /// var writeValue = DeviceStatus.Write(0)  // Initialize with all zeros
  /// writeValue.powerEnabled = true          // Set power enabled bit
  /// writeValue.deviceMode = .normal         // Set device mode
  ///
  /// // Write the value to the register
  /// statusRegister.write(writeValue)
  /// ```
  ///
  /// All register accesses through Swift MMIO use volatile semantics to ensure
  /// correct interaction with hardware. See <doc:Volatile-Access> to learn
  /// more.
  ///
  /// - Warning: This method performs a direct write, overwriting all bits in
  ///   the register. If you intend to modify only specific fields while
  ///   preserving others, use the ``modify(_:)`` method instead, which performs
  ///   a read-modify-write operation.
  ///
  /// - Parameter newValue: A `Value.Write` instance containing the data to be
  ///   written.
  @inlinable @inline(__always)
  public func write(_ newValue: Value.Write) {
    let storage = Value.Raw(newValue).storage
    #if FEATURE_INTERPOSABLE
    if let interposer = self.interposer {
      interposer.store(storage, to: self.pointer)
    } else {
      Value.Raw.Storage.store(storage, to: self.pointer)
    }
    #else
    Value.Raw.Storage.store(storage, to: self.pointer)
    #endif
  }

  /// Constructs a `Value.Write` view within a closure and writes its contents to 
  /// the register.
  ///
  /// This is a convenience method for preparing and writing a new value to the
  /// register in a single operation. The `Value.Write` view passed to the `body`
  /// closure is initialized with all bits set to zero. You configure this view
  /// within the closure, and its final state is then written to the hardware 
  /// register.
  ///
  /// ```swift
  /// // Write to the register using a closure
  /// statusRegister.write { view in
  ///     // view starts as all zeros
  ///     view.powerEnabled = true      // Set power enabled bit
  ///     view.deviceMode = .normal     // Set device mode
  /// }
  /// ```
  ///
  /// All register accesses through Swift MMIO use volatile semantics to ensure
  /// correct interaction with hardware. See <doc:Volatile-Access> to learn
  /// more.
  ///
  /// - Warning: This method performs a direct write, overwriting all bits in
  ///   the register. If you intend to modify only specific fields while
  ///   preserving others, use the ``modify(_:)`` method instead, which performs
  ///   a read-modify-write operation.
  ///
  /// - Parameter body: A closure that receives an `inout Value.Write` view.
  ///   Modify this view to set the desired register state.
  ///
  /// - Returns: The value returned by the `body` closure, if any.
  @inlinable @inline(__always)
  public func write<T>(_ body: (inout Value.Write) -> (T)) -> T {
    var newValue = Value.Write(Value.Raw(0))  // Initialize with all zeros
    let returnValue = body(&newValue)
    self.write(newValue)
    return returnValue
  }

  /// Performs a volatile read-modify-write operation on the register.
  ///
  /// This method reads the current value from the register, provides both the
  /// read view and a write view (initialized from the read view) to your
  /// closure for modification, and then writes the (potentially) modified write
  /// view back to the register.
  ///
  /// ```swift
  /// // Modify the register based on its current state
  /// statusRegister.modify { currentValue, newValue in
  ///     // currentValue is the state read from hardware
  ///     // newValue is initialized from currentValue and can be modified
  ///     
  ///     if currentValue.statusFlag {
  ///         // Respond to the current status
  ///         newValue.controlSetting = .optionA
  ///     }
  ///     
  ///     // Update other fields
  ///     newValue.anotherField = .updatedValue
  /// }
  /// ```
  ///
  /// All register accesses through Swift MMIO use volatile semantics to ensure
  /// correct interaction with hardware. See <doc:Volatile-Access> to learn
  /// more.
  ///
  /// - Parameter body: A closure that receives the `Value.Read` view
  ///   (representing the register's state at the time of the read) and an
  ///   `inout Value.Write` view for modification.
  ///
  /// - Returns: The value returned by the `body` closure, if any.
  @inlinable @inline(__always) @_disfavoredOverload
  public func modify<T>(_ body: (Value.Read, inout Value.Write) -> (T)) -> T {
    let value = self.read()
    var newValue = Value.Write(value)  // Initialize Write view from Read view
    let returnValue = body(value, &newValue)
    self.write(newValue)
    return returnValue
  }
}

extension Register where Value.Read == Value.Write {
  // FIXME: Hide overload/base from code completion
  // blocked-by: rdar://116586222 (Hide overload+base method if overload is
  //   marked as deprecated in protocol specialization)
  //
  // swift-format-ignore
  @_documentation(visibility: internal)
  @available(
    *,
    deprecated,
    message: """
      For registers with symmetric Read/Write views (only ReadWrite/Reserved fields), \
      use the 'modify' method with a single 'inout ReadWrite' parameter: \
      'myRegister.modify { view in ... }'.
      """)
  @inlinable @inline(__always) @_disfavoredOverload
  public func modify<T>(_ body: (Value.Read, inout Value.Write) -> (T)) -> T {
    var value = self.read() // Value.Read is also Value.Write
    let returnValue = body(value, &value)
    self.write(value)
    return returnValue
  }

  /// Performs an volatile read-modify-write operation on a symmetric register.
  ///
  /// This is a specialized version of ``modify(_:)`` for registers
  /// where the `Read` and `Write` views are the same type. This occurs when a
  /// register definition contains only ``MMIO/ReadWrite(bits:as:)`` and
  /// ``MMIO/Reserved(bits:as:)`` bit fields.
  ///
  /// ```swift
  /// // Modify a symmetric register
  /// controlRegister.modify { view in
  ///     // view is initialized with the current hardware state
  ///     view.enableFlag = true
  ///     view.mode = .highPerformance
  ///     view.prescaler += 1  // Increment based on current value
  /// }
  /// ```
  ///
  /// This method reads the register, provides an `inout` view (which serves as 
  /// both the read and write context) to the `body` closure for modification,
  /// and then writes the (potentially) modified view back to the hardware
  /// register.
  ///
  /// This is the most common and idiomatic way to modify registers with
  /// symmetric read/write fields.
  ///
  /// All register accesses through Swift MMIO use volatile semantics to ensure
  /// correct interaction with hardware. See <doc:Volatile-Access> to learn
  /// more.
  ///
  /// - Parameter body: A closure that receives an `inout Value.Write`
  ///   (which is also `Value.Read`) view for modification.
  ///
  /// - Returns: The value returned by the `body` closure, if any.
  @inlinable @inline(__always)
  public func modify<T>(_ body: (inout Value.Write) -> (T)) -> T {
    var value = self.read()  // Value.Read is also Value.Write
    let returnValue = body(&value)
    self.write(value)
    return returnValue
  }
}
