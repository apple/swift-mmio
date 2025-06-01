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

/// A protocol defining the layout and access semantics of a hardware register.
///
/// Types conforming to `RegisterValue` describe the structure of a single
/// hardware register, including its bit fields and their access properties.
/// Conformance is achieved automatically by applying the
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
public protocol RegisterValue {
  /// The type providing raw, untyped access to this register's underlying
  /// storage.
  ///
  /// This associated type must conform to ``RegisterValueRaw`` and exposes
  /// direct manipulation of the register's bits as integer segments.
  associatedtype Raw: RegisterValueRaw where Raw.Value == Self

  /// The type providing typed, read-only access to this register's bit fields.
  ///
  /// This associated type must conform to ``RegisterValueRead`` and exposes
  /// properties for each readable bit field.
  associatedtype Read: RegisterValueRead where Read.Value == Self

  /// The type providing typed, write-access to this register's bit fields.
  ///
  /// This associated type must conform to ``RegisterValueWrite`` and exposes
  /// properties for each writable bit field.
  associatedtype Write: RegisterValueWrite where Write.Value == Self
}

/// A protocol for the raw, untyped view of a register's value.
///
/// This protocol defines an interface for accessing a register's content as a
/// single, uninterpreted integer value (`Storage`). It's primarily used
/// internally by Swift MMIO for:
///
/// - Converting between the different typed views (``RegisterValueRead``,
///   ``RegisterValueWrite``) of a register.
/// - Providing an escape hatch for low-level manipulation if necessary, though
///   direct use is generally discouraged in favor of typed field access.
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

  /// Initializes a `Raw` view with a specific integer storage value.
  ///
  /// - Parameter storage: The raw integer value to represent.
  init(_ storage: Storage)

  /// Initializes a `Raw` view from a typed `Read` view of the register.
  ///
  /// - Parameter read: The `Read` view to convert from.
  init(_ read: Value.Read)

  /// Initializes a `Raw` view from a typed `Write` view of the register.
  ///
  /// - Parameter write: The `Write` view to convert from.
  init(_ write: Value.Write)
}

/// A protocol for the typed, read-only view of a register.
///
/// A `Read` view is usually obtained by calling ``Register/read()``, which
/// populates it with the current hardware state of the register.
public protocol RegisterValueRead {
  /// A type alias back to the primary ``RegisterValue``-conforming type that
  /// this read view is associated with.
  associatedtype Value: RegisterValue where Value.Read == Self

  /// Initializes a `Read` view from a `Raw` view of the register.
  ///
  /// - Parameter raw: The `Raw` view containing the register data.
  init(_ raw: Value.Raw)
}

extension RegisterValueRead {
  /// Provides mutable access to the underlying raw data of this `Read` view.
  ///
  /// This property allows direct manipulation of the view's bits. Use this with
  /// caution, as changes made here bypass typed field accessors.
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
/// A `Write` view can be initialized from a `Raw` view (to start with a
/// specific bit pattern) or from a `Read` view for read-modify-write
/// operations, ensuring that unchanged fields retain the hardware's current
/// values.
public protocol RegisterValueWrite {
  /// A type alias back to the primary ``RegisterValue``-conforming type that
  /// this write view is associated with.
  associatedtype Value: RegisterValue where Value.Write == Self

  /// Initializes a `Write` view from a `Raw` view of the register.
  ///
  /// - Parameter raw: The `Raw` view to convert from.
  init(_ raw: Value.Raw)

  /// Initializes a `Write` view from a `Read` view of the same register.
  ///
  /// - Parameter read: The `Read` view to convert from.
  init(_ read: Value.Read)
}

extension RegisterValueWrite {
  /// Provides mutable access to the underlying raw data of this `Write` view.
  ///
  /// This property allows direct manipulation of the view's bits. Use this with
  /// caution, as changes made here bypass typed field accessors.
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
