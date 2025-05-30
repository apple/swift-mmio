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

/// A protocol defining the layout and access semantics of a hardware register.
///
/// Types conforming to `RegisterValue` describe the structure of a single
/// hardware register, including its bit fields and their access properties.
/// Conformance is typically achieved automatically by applying the
/// ``MMIO/Register(bitWidth:)`` macro to a `struct` definition.
///
/// `RegisterValue` acts as a blueprint for a register. It connects the
/// high-level, human-readable definition of a register (with named bit fields
/// and optional type projections) to three specialized views for interaction:
///
/// - ``Raw``: Untyped, raw integer access to the register's storage.
/// - ``Read``: Typed, read-only access to the register's readable bit fields.
/// - ``Write``: Typed modification of the register's writable bit fields.
///
/// These views are used by the ``Register`` type to perform actual hardware
/// read and write operations.
///
/// - Note: You usually do not need to conform types to this protocol
///   manually; the ``MMIO/Register(bitWidth:)`` macro handles this.
///
/// - SeeAlso: ``RegisterValueRaw``, ``RegisterValueRead``, ``RegisterValueWrite``.
public protocol RegisterValue {
  /// The type providing raw, untyped access to this register's underlying
  /// storage.
  ///
  /// This associated type must conform to ``RegisterValueRaw`` and is used
  /// for direct manipulation of the register's bits as a single integer.
  associatedtype Raw: RegisterValueRaw where Raw.Value == Self
  /// The type providing typed, read-only access to this register's bit fields.
  ///
  /// This associated type must conform to ``RegisterValueRead`` and exposes
  /// properties for each readable bit field, potentially with
  /// <doc:Type-Projections>.
  associatedtype Read: RegisterValueRead where Read.Value == Self
  /// The type providing typed, write-access to this register's bit fields.
  ///
  /// This associated type must conform to ``RegisterValueWrite`` and allows
  /// modification of writable bit fields.
  associatedtype Write: RegisterValueWrite where Write.Value == Self
}

/// A protocol for the raw, untyped view of a register's value.
///
/// This protocol defines an interface for accessing a register's content as a
/// single, uninterpreted integer value (`Storage`). It's primarily used
/// internally by Swift MMIO for:
///
/// - Converting between the different typed views (``RegisterValueRead``,
///   ``RegisterValueWrite``).
///   of a register.
/// - Performing the fundamental load and store operations to hardware.
/// - Providing an escape hatch for low-level manipulation if necessary, though
///   direct use is generally discouraged in favor of typed field access.
///
/// A `Raw` view holds the register's data in its `storage` property. It can be
/// initialized from its `Storage` type, or from a `Read` or `Write` view of the
/// same register.
///
/// - SeeAlso: ``RegisterValue``.
public protocol RegisterValueRaw {
  /// A type alias back to the primary ``RegisterValue``-conforming type that
  /// this raw view is associated with.
  associatedtype Value: RegisterValue where Value.Raw == Self
  /// The underlying fixed-width, unsigned integer type that stores
  /// the register's data (e.g., `UInt8`, `UInt16`, `UInt32`, `UInt64`).
  /// This type must also conform to `_RegisterStorage` to ensure that all
  /// memory accesses are volatile.
  associatedtype Storage: FixedWidthInteger & UnsignedInteger & _RegisterStorage

  /// The raw integer value of the register.
  var storage: Storage { get set }

  /// Initializes a raw view with a specific integer storage value.
  /// - Parameter storage: The raw integer value to represent.
  init(_ storage: Storage)
  /// Initializes a raw view from a typed `Read` view of the register.
  /// This effectively extracts the underlying raw data from the `Read` view.
  /// - Parameter value: The `Read` view to convert from.
  init(_ value: Value.Read)
  /// Initializes a raw view from a typed `Write` view of the register.
  /// This captures the currently staged raw data from the `Write` view.
  /// - Parameter value: The `Write` view to convert from.
  init(_ value: Value.Write)
}

/// A protocol for the typed, read-only view of a register.
///
/// This protocol defines an interface for accessing a register's readable bit
/// fields in a type-safe manner. When a ``RegisterValue`` is defined, its
/// `Read` view will have properties corresponding to each readable bit field.
///
/// Accessing these properties returns values projected to their
/// specified Swift types (e.g., `Bool`, custom enums) if
/// ``BitFieldProjectable`` types were used in the register's definition.
///
/// A `Read` view is usually obtained by calling ``Register/read()``, which
/// populates it with the current hardware state of the register.
///
/// - SeeAlso: ``RegisterValue``.
public protocol RegisterValueRead {
  /// A type alias back to the primary ``RegisterValue``-conforming type that this
  /// read view is associated with.
  associatedtype Value: RegisterValue where Value.Read == Self

  /// Initializes a `Read` view from a `Raw` view of the register.
  ///
  /// This initializer is typically used internally after a hardware read operation
  /// has fetched the raw data into a `Raw` view. The `Read` view then interprets
  /// this raw data according to the register's bit field definitions.
  /// - Parameter value: The `Raw` view containing the register data.
  init(_ value: Value.Raw)
}

extension RegisterValueRead {
  /// Provides mutable access to the underlying raw data of this `Read` view.
  ///
  /// This property allows direct manipulation of the register's bits, bypassing
  /// the typed field accessors. It should be used with caution, as
  /// modifications made through this raw view are not checked against field
  /// access rules (e.g., writing to a ``MMIO/ReadOnly(bits:as:)`` field's bits)
  /// or type projections.
  ///
  /// The primary use case for modifying `raw` on a `Read` view is for testing
  /// or simulation purposes where you might want to construct a specific `Read`
  /// view state without performing an actual hardware read.
  ///
  /// When read, it returns a ``RegisterValueRaw`` instance representing the
  /// current data of this `Read` view. When modified (e.g.,
  /// `myReadView.raw.storage = ...`), the `Read` view is updated to reflect the
  /// changes made to the raw data.
  ///
  /// - Warning: While this property provides `_modify` access, conceptually a
  ///   `Read` view represents a snapshot. Modifying its `raw` storage changes
  ///   that snapshot, not the hardware register itself.
  @_disfavoredOverload
  @inlinable @inline(__always)
  public var raw: Value.Raw {
    _read {
      yield Value.Raw(self)
    }
    _modify {
      var raw = Value.Raw(self)
      yield &raw
      self = Self(raw)
    }
  }
}

/// A protocol for the typed, write-access view of a register.
///
/// This protocol defines an interface for preparing data to be written to a
/// hardware register. Its properties correspond to the writable bit fields defined
/// in the associated ``RegisterValue`` layout.
///
/// ## Overview
/// Assigning values to these properties stages the changes. The actual write to
/// the hardware register occurs when this `Write` view is passed to
/// ``Register/write(_:)`` or used within the closure of ``Register/modify(_:)``.
///
/// A `Write` view can be initialized from a `Raw` view (to start with a specific
/// bit pattern) or from a `Read` view (essential for read-modify-write operations,
/// ensuring that unchanged fields retain their current hardware values).
///
/// - SeeAlso: ``RegisterValue``.
public protocol RegisterValueWrite {
  /// A type alias back to the primary ``RegisterValue``-conforming type that this
  /// write view is associated with.
  associatedtype Value: RegisterValue where Value.Write == Self

  /// Initializes a `Write` view from a `Raw` view of the register.
  ///
  /// This allows constructing a `Write` view based on a specific raw integer
  /// bit pattern, which can then be further modified through typed field accessors
  /// before being written to hardware.
  /// - Parameter value: The `Raw` view containing the initial data for this `Write` view.
  init(_ value: Value.Raw)

  /// Initializes a `Write` view from a `Read` view of the same register.
  ///
  /// This is a critical initializer for performing read-modify-write operations.
  /// It ensures that the `Write` view starts with the current state of the
  /// hardware register (as captured by the `Read` view). Subsequent modifications
  /// to the `Write` view will only affect the targeted fields, preserving the
  /// values of other fields.
  /// - Parameter read: The `Read` view representing the current hardware state.
  init(_ read: Value.Read)
}

extension RegisterValueWrite {
  /// Provides mutable access to the underlying raw data being prepared for a write operation.
  ///
  /// This property allows direct manipulation of the register's bits before the
  /// `Write` view is committed to hardware. Use this with caution, as changes
  /// made here bypass typed field accessors and their associated checks or
  /// projections.
  ///
  /// When read, it returns a ``RegisterValueRaw`` instance representing the currently
  /// staged data in this `Write` view. When modified (e.g., `myWriteView.raw.storage = ...`),
  /// the `Write` view's staged data is updated.
  ///
  /// - Warning: Reading from `raw` on a `Write` view provides the currently
  ///   staged raw value, which may not reflect the current state of the actual
  ///   hardware register until a ``Register/write(_:)`` or ``Register/modify(_:)``
  ///   operation is completed.
  @inlinable @inline(__always)
  public var raw: Value.Raw {
    _read {
      yield Value.Raw(self)
    }
    _modify {
      var raw = Value.Raw(self)
      yield &raw
      self = Self(raw)
    }
  }
}
