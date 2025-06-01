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

/// A protocol for types that can represent bit field values in a type-safe
/// manner.
///
/// Conforming to `BitFieldProjectable` allows a custom Swift type to be used as
/// the representation for a bit field, rather than directly manipulating raw
/// integer values. This is enabled by using the `as: SomeType.self` parameter
/// in bit field macros like ``MMIO/ReadWrite(bits:as:)``.
///
/// For detailed guidance, see <doc:Custom-BitFieldProjectable>.
public protocol BitFieldProjectable {
  /// The number of bits this type occupies within the register field.
  ///
  /// This static property must match the width of the bit field as defined in
  /// your register macro (e.g., `bits: 4..<6` is 2 bits wide). A mismatch will
  /// cause a runtime trap when accessing the register.
  static var bitWidth: Int { get }

  /// Converts a raw integer value to this type when reading a register.
  ///
  /// This initializer is called when a register is read, and the raw value of
  /// the bit field needs to be converted into this `BitFieldProjectable` type.
  ///
  /// - Parameter storage: The masked and shifted value from the bit field,
  ///   guaranteed to be truncated to `Self.bitWidth` bits.
  @inlinable @inline(__always)
  init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger

  /// Converts this type to a raw integer value when writing to a register.
  ///
  /// This method is called when a bit field is being written to. The returned
  /// value must fit within `Self.bitWidth` bits or a runtime trap will occur.
  ///
  /// - Parameter type: The target integer type for the bit field.
  /// - Returns: A value that fits within `Self.bitWidth` bits.
  @inlinable @inline(__always)
  func storage<Storage>(_ type: Storage.Type) -> Storage
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

/// Default implementation for `FixedWidthInteger` types.
///
/// Conforming a `FixedWidthInteger` type (like `UInt8`, `Int16`) to
/// `BitFieldProjectable` generally does not require any additional
/// customization beyond declaring conformance.
extension BitFieldProjectable where Self: FixedWidthInteger {
  @inlinable @inline(__always)
  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger {
    let storageBitWidth = MemoryLayout<Storage>.size * 8
    #if hasFeature(Embedded)
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
    self = Self(storage)
  }

  @inlinable @inline(__always)
  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger {
    let storageBitWidth = MemoryLayout<Storage>.size * 8
    #if hasFeature(Embedded)
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

/// Default implementation for `RawRepresentable` types with `FixedWidthInteger`
/// raw values.
///
/// To conform a `RawRepresentable` enum or struct (e.g., an
/// `enum MyState: UInt8`), you typically only need to implement the static
/// `bitWidth` requirement. The conversion to and from storage is handled by
/// this extension.
extension BitFieldProjectable
where Self: RawRepresentable, RawValue: FixedWidthInteger {
  @inlinable @inline(__always)
  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger {
    let storageBitWidth = MemoryLayout<Storage>.size * 8
    #if hasFeature(Embedded)
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

    let rawValue = RawValue(storage)
    guard let value = Self(rawValue: rawValue) else {
      #if hasFeature(Embedded)
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

  @inlinable @inline(__always)
  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger {
    let storageBitWidth = MemoryLayout<Storage>.size * 8
    #if hasFeature(Embedded)
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
