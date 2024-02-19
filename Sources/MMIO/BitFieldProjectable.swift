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

public protocol BitFieldProjectable {
  static var bitWidth: Int { get }

  @inlinable @inline(__always)
  init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger

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

  @inlinable @inline(__always)
  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger {
    self = storage != 0b0
  }

  @inlinable @inline(__always)
  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger {
    self ? 0b1 : 0b0
  }
}

/// Default implementation of `BitFieldProjectable` for `RawRepresentable`
/// types.
///
/// Conforming a `RawRepresentable` type to `BitFieldProjectable` only needs to
/// implement ``BitFieldProjectable.bitWidth``.
extension RawRepresentable
where Self: BitFieldProjectable, RawValue: FixedWidthInteger {
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
      Value type '\(Self.self)' of bit width '\(storageBitWidth)' cannot be \
      formed from storage '\(storage)' of bit width '\(Self.bitWidth)'
      """)
    #endif

    // Convert the storage integer type to the raw value type of `Self`. If the
    // run-time value of `storage` is not representable by `RawValue`, the
    // program will trap.
    // FIXME: add a custom precondition with a more descriptive error
    let rawValue = RawValue(storage)

    // Attempt to form a valid value of `Self` from the `rawValue`.
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
      Storage type '\(Self.self)' of bit width '\(storageBitWidth)' cannot \
      represent value '\(self)' of bit width '\(Self.bitWidth)'
      """)
    #endif
    return Storage(rawValue)
  }
}

@inlinable @inline(__always)
public func preconditionMatchingBitWidth(
  _ fieldType: (some BitField).Type,
  _ projectedType: (some BitFieldProjectable).Type,
  file: StaticString = #file,
  line: UInt = #line
) {
  #if hasFeature(Embedded)
  // FIXME: Embedded doesn't have static interpolated strings yet
  precondition(
    fieldType.bitWidth == projectedType.bitWidth,
    "Illegal projection of bit-field as type of differing bit-width",
    file: file,
    line: line)
  #else
  precondition(
    fieldType.bitWidth == projectedType.bitWidth,
    """
    Illegal projection of \(fieldType.bitWidth) bit bit-field '\(fieldType)' \
    as \(projectedType.bitWidth) bit type '\(projectedType)'
    """,
    file: file,
    line: line)
  #endif
}
