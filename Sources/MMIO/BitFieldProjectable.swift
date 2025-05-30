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

/// A protocol for types that can be used to represent the value of a bit field
/// in a type-safe manner, abstracting away the raw integer storage.
///
/// Conforming to `BitFieldProjectable` allows a custom Swift type to be used as
/// the representation for a bit field, rather than directly manipulating raw
/// integer segments. This is enabled by using the `as: SomeType.self` parameter
/// in bit field macros like ``ReadWrite(bits:as:)``.
///
/// The conforming type must define how it converts to and from the underlying
/// raw integer `Storage` of the bit field.
///
/// For detailed guidance on using type projections,
/// see <doc:Custom-BitFieldProjectable>.
public protocol BitFieldProjectable {
  /// The number of bits this projected type occupies within the register field.
  ///
  /// This static property must accurately reflect the width of the bit field
  /// this type is intended to project. A mismatch between this `bitWidth` and
  /// the width defined in the bit field macro results in a runtime precondition
  /// failure.
  static var bitWidth: Int { get }

  /// Initializes an instance of the projecting type from a raw integer
  /// `Storage` value.
  ///
  /// This initializer is called when a register is read, and the raw value of
  /// the bit field needs to be converted into this `BitFieldProjectable` type.
  ///
  /// - Parameter storage: The raw unsigned integer value extracted from the
  ///   bit field. The calling context (bit field accessors) ensures this value
  ///   is already masked and shifted, effectively truncating it to
  ///   `Self.bitWidth`.
  ///
  /// - Precondition: The provided `storage` value (when interpreted as
  ///   `Self.bitWidth` bits) must be representable by this type. For example,
  ///   if this type is an enum, the `storage` value must correspond to a valid
  ///   `RawValue`.
  @inlinable @inline(__always)
  init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger

  /// Converts an instance of the projecting type back into a raw integer
  /// `Storage` value.
  ///
  /// This method is called when a bit field is being written to. The returned
  /// raw integer value will be placed into the appropriate bits of the
  /// register.
  ///
  /// - Parameter type: The target `Storage` type, which must be a `FixedWidthInteger`
  ///   and `UnsignedInteger`. This type parameter indicates the required integer
  ///   type for the bit field's segment in the hardware register.
  ///
  /// - Returns: The raw unsigned integer representation of this instance, suitable
  ///   for writing to the bit field. This value should fit within `Self.bitWidth`.
  @inlinable @inline(__always)
  func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger
}

extension Never: BitFieldProjectable {
  public static var bitWidth: Int { fatalError() }

  @inlinable @inline(__always)
  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger { fatalError() }

  @inlinable @inline(__always)
  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger { fatalError() }
}

extension Bool: BitFieldProjectable {
  public static let bitWidth = 1

  /// Initializes a `Bool` from a storage value.
  ///
  /// `true` if `storage` is non-zero, `false` otherwise.
  @inlinable @inline(__always)
  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger {
    self = storage != 0b0
  }

  /// Converts this `Bool` to a storage value.
  ///
  /// `1` if `true`, `0` if `false`.
  @inlinable @inline(__always)
  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger {
    self ? 0b1 : 0b0
  }
}

/// Default implementation of `BitFieldProjectable` for types conforming to
/// `FixedWidthInteger`.
///
/// Conforming a `FixedWidthInteger` type (like `UInt8`, `Int16`) to
/// `BitFieldProjectable` generally does not require any additional
/// customization beyond declaring conformance. The `bitWidth` is implicitly
/// derived from the integer type itself.
extension BitFieldProjectable where Self: FixedWidthInteger {
  /// Initializes an instance from a raw storage value.
  ///
  /// - Precondition: The `storage` type's bit width must be sufficient to represent
  ///   `Self.bitWidth` bits. The `storage` value itself must be representable by `Self`.
  @inlinable @inline(__always)
  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger {
    // Ensure the storage type can fully represent all the bits of `Self`.
    let storageBitWidth = MemoryLayout<Storage>.size * 8
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      storageBitWidth >= Self.bitWidth,
      "Value cannot be formed from storage type")
    #else
    precondition(
      storageBitWidth >= Self.bitWidth,
      """
      Value type '\(Self.self)' of bit width '\(Self.bitWidth)' cannot be \
      formed from storage '\(storage)' of bit width '\(storageBitWidth)'
      """)
    #endif

    // Convert the storage integer type to `Self`.
    self = Self(storage)
  }

  /// Converts this instance to a raw storage value.
  ///
  /// - Precondition: The target `Storage` type's bit width must be sufficient to
  ///   represent `Self.bitWidth` bits.
  @inlinable @inline(__always)
  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger {
    // Ensure the storage type can fully represent all the bits of `Self`.
    let storageBitWidth = MemoryLayout<Storage>.size * 8
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      storageBitWidth >= Self.bitWidth,
      "Storage type cannot represent value")
    #else
    precondition(
      storageBitWidth >= Self.bitWidth,
      """
      Storage type '\(Storage.self)' of bit width '\(storageBitWidth)' cannot \
      represent value '\(self)' of bit width '\(Self.bitWidth)'
      """)
    #endif
    return Storage(self)
  }
}

extension UInt8: BitFieldProjectable {}
extension UInt16: BitFieldProjectable {}
extension UInt32: BitFieldProjectable {}
extension UInt64: BitFieldProjectable {}

extension Int8: BitFieldProjectable {}
extension Int16: BitFieldProjectable {}
extension Int32: BitFieldProjectable {}
extension Int64: BitFieldProjectable {}

/// Default implementation of `BitFieldProjectable` for types conforming to
/// `RawRepresentable` where `RawValue` is a `FixedWidthInteger`.
///
/// To conform a `RawRepresentable` enum or struct (e.g., an `enum MyState: UInt8`),
/// you typically only need to implement the static ``BitFieldProjectable/bitWidth``
/// requirement. The conversion to and from storage is handled by this extension.
extension BitFieldProjectable
where Self: RawRepresentable, RawValue: FixedWidthInteger {
  /// Initializes an instance from a raw storage value using its `RawValue`.
  ///
  /// - Precondition:
  ///   - The `storage` type's bit width must be sufficient for `Self.bitWidth`.
  ///   - The `storage` value, when converted to `Self.RawValue`, must correspond
  ///     to a valid raw value for `Self`. If `Self(rawValue:)` returns `nil`,
  ///     this initializer will trap.
  @inlinable @inline(__always)
  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger {
    // Ensure the storage type can fully represent all the bits of `Self`.
    let storageBitWidth = MemoryLayout<Storage>.size * 8
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      storageBitWidth >= Self.bitWidth,
      "Value cannot be formed from storage type")
    #else
    precondition(
      storageBitWidth >= Self.bitWidth,
      """
      Value type '\(Self.self)' of bit width '\(Self.bitWidth)' cannot be \
      formed from storage '\(storage)' of bit width '\(storageBitWidth)'
      """)
    #endif

    // Convert the storage integer type to the raw value type of `Self`. If the
    // run-time value of `storage` is not representable by `RawValue`, the
    // program will trap.
    // FIXME: add a custom precondition with a more descriptive error
    let rawValue = RawValue(storage)

    // Attempt to form a valid instance of `Self` from the `rawValue`.
    guard let value = Self(rawValue: rawValue) else {
      // Trap if the `rawValue` is not a valid value of `Self`.
      #if hasFeature(Embedded)
      // FIXME: Embedded doesn't have static interpolated strings yet
      preconditionFailure("Illegal value does not correspond to any raw value")
      #else
      preconditionFailure(
        """
        Illegal value '\(storage)' does not correspond to any raw value of \
        '\(Self.self)'
        """)
      #endif
    }
    self = value
  }

  /// Converts this instance to a raw storage value via its `RawValue`.
  ///
  /// - Precondition: The target `Storage` type's bit width must be sufficient
  ///   for `Self.bitWidth`. The `rawValue` of this instance must be representable
  ///   by the `Storage` type.
  @inlinable @inline(__always)
  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger {
    // Ensure the storage type can fully represent all the bits of `Self`.
    let storageBitWidth = MemoryLayout<Storage>.size * 8
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      storageBitWidth >= Self.bitWidth,
      "Storage type cannot represent value")
    #else
    precondition(
      storageBitWidth >= Self.bitWidth,
      """
      Storage type '\(Storage.self)' of bit width '\(storageBitWidth)' cannot \
      represent value '\(self)' of bit width '\(Self.bitWidth)'
      """)
    #endif
    return Storage(rawValue)
  }
}
