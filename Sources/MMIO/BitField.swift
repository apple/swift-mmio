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

// Explore bit field refactor:
// * requires variadic pack iteration
// * requires metadata-less variadic packs
// - protocol BitField with (least|most) significant bit requirements
// - FixedWidthInteger.subscript[(variadic T: BitField)] -> Storage

/// A protocol representing a logical field within a hardware register.
///
/// `BitField` provides a common interface for extracting a field's value from
/// and inserting it into a register's raw storage. It also defines
/// interactions with ``BitFieldProjectable`` types, allowing fields to be
/// represented by more expressive Swift types.
///
/// - Note: The bit field macros no longer generate types that conform to this
///   protocol.
@available(
  *, deprecated,
  message:
    "The bit field macros no longer generate types that conform to this protocol."
)
public protocol BitField {
  /// The underlying integer type of the register this bit field belongs to.
  ///
  /// This type must conform to `FixedWidthInteger` and `UnsignedInteger`,
  /// representing the raw storage of the register (e.g., `UInt32`).
  associatedtype Storage: FixedWidthInteger & UnsignedInteger

  /// The type this bit field projects to, if a type projection is specified.
  ///
  /// If no projection (e.g., `as: SomeType.self` in a bit field macro) is used,
  /// this defaults to `Never`. Otherwise, it's a custom type that must conform
  /// to ``BitFieldProjectable``.
  associatedtype Projection: BitFieldProjectable

  /// The total width of this logical bit field, in bits.
  ///
  /// For a field that occupies more than one bit range, this is the sum of the
  /// widths of all its bit ranges.
  static var bitWidth: Int { get }

  /// Inserts the bit field's raw `value` into the `storage` of a register.
  ///
  /// This method takes a `value` representing the data for this bit field
  /// (already masked to fit within `Self.bitWidth`) and places it into the
  /// correct bit positions within the `inout storage` parameter, which
  /// represents the entire register's raw value.
  ///
  /// - Parameters:
  ///   - value: The raw integer value for this bit field.
  ///   - storage: An `inout` parameter representing the register's
  ///     raw value, which is modified in place.
  static func insertBits(_ value: Storage, into storage: inout Storage)

  /// Extracts the raw integer value of this bit field from a register's
  /// `storage`.
  ///
  /// This method reads the appropriate bits from the `storage` (the entire
  /// register's raw value), right-aligns them (so the LSB of the field is at
  /// bit 0 of the returned value), and masks the result to `Self.bitWidth`.
  ///
  /// - Parameter storage: The entire register's raw value.
  /// - Returns: The raw integer value of this bit field.
  static func extractBits(from storage: Storage) -> Storage

  /// Inserts a projected value into the register's `storage`.
  ///
  /// This method converts the given `value` of `Projection` type into its raw
  /// `Storage` representation using ``BitFieldProjectable/storage(_:)``,
  /// and then uses ``insertBits(_:into:)`` to place it in the `storage`.
  ///
  /// - Precondition: `Self.bitWidth` must equal `Projection.bitWidth`.
  ///   A mismatch indicates an invalid projection and causes a runtime trap.
  ///
  /// - Parameters:
  ///   - value: The projected value to insert.
  ///   - storage: An `inout` parameter for the register's raw value.
  static func insert(_ value: Projection, into storage: inout Storage)

  /// Extracts a projected value from the register's `storage`.
  ///
  /// This method first calls ``extractBits(from:)`` to get the raw integer
  /// value of the field, then initializes an instance of the `Projection` type
  /// using ``BitFieldProjectable/init(storage:)``.
  ///
  /// - Precondition: `Self.bitWidth` must equal `Projection.bitWidth`.
  ///   A mismatch indicates an invalid projection and causes a runtime trap.
  ///
  /// - Parameter storage: The register's raw value.
  ///
  /// - Returns: An instance of the `Projection` type.
  static func extract(from storage: Storage) -> Projection
}

// Default implementations for insert/extract for Projection
@available(*, deprecated)
extension BitField {
  @inlinable @inline(__always)
  static func preconditionMatchingBitWidth(
    file: StaticString = #file,
    line: UInt = #line
  ) {
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      Self.bitWidth == Projection.bitWidth,
      "Illegal projection of bit-field as type of differing bit-width",
      file: file,
      line: line)
    #else
    precondition(
      Self.bitWidth == Projection.bitWidth,
      """
      Illegal projection of \(Self.bitWidth) bit bit-field '\(Self.self)' \
      as \(Projection.bitWidth) bit type '\(Projection.self)'
      """,
      file: file,
      line: line)
    #endif
  }

  @inlinable @inline(__always)
  public static func insert(_ value: Projection, into storage: inout Storage) {
    Self.preconditionMatchingBitWidth()
    Self.insertBits(value.storage(Storage.self), into: &storage)
  }

  @inlinable @inline(__always)
  public static func extract(from storage: Self.Storage) -> Projection {
    Self.preconditionMatchingBitWidth()
    return Projection(storage: Self.extractBits(from: storage))
  }
}

/// A protocol for bit fields that occupy a single, contiguous range of bits
/// within a register.
///
/// - Note: The bit field macros no longer generate types that conform to this
///   protocol.
@available(
  *, deprecated,
  message:
    "The bit field macros no longer generate types that conform to this protocol."
)
public protocol ContiguousBitField: BitField {
  /// The range of bits this field occupies within the register (e.g., `0..<4`
  /// for bits 0, 1, 2, 3).
  static var bitRange: Range<Int> { get }

  /// The offset of this field, representing the position of its least
  /// significant bit (LSB).
  static var bitOffset: Int { get }

  /// A bit mask representing the width of this field, right-aligned.
  ///
  /// For a field of `N` bits, this mask is `(1 << N) - 1`.
  static var bitMask: Storage { get }
}

// Default implementations for ContiguousBitField
@available(*, deprecated)
extension ContiguousBitField {
  @inlinable @inline(__always)
  public static var bitWidth: Int {
    Self.bitRange.upperBound - Self.bitRange.lowerBound
  }

  @inlinable @inline(__always)
  public static var bitOffset: Int { Self.bitRange.lowerBound }

  @inlinable @inline(__always)
  public static var bitMask: Storage { (1 << Self.bitWidth) &- 1 }

  // FIXME: value.bitWidth <= Self.bitWidth <= Storage.bitWidth
  @inlinable @inline(__always)
  public static func insertBits(_ value: Storage, into storage: inout Storage) {
    storage[bits: Self.bitRange] = value
  }

  @inlinable @inline(__always)
  public static func extractBits(from storage: Storage) -> Storage {
    storage[bits: Self.bitRange]
  }
}

/// A protocol for bit fields that are composed of multiple, non-adjacent
/// (discontiguous) segments of bits within a register.
///
/// - Note: The bit field macros no longer generate types that conform to this
///   protocol.
@available(
  *, deprecated,
  message:
    "The bit field macros no longer generate types that conform to this protocol."
)
public protocol DiscontiguousBitField: BitField {
  /// An array of bit ranges that make up this logical field.
  ///
  /// - Precondition: Bit bitRanges must not overlap.
  static var bitRanges: [Range<Int>] { get }
}

// Default implementations for DiscontiguousBitField
@available(*, deprecated)
extension DiscontiguousBitField {
  @inlinable @inline(__always)
  public static var bitWidth: Int {
    var bitWidth = 0
    for bitRange in Self.bitRanges {
      bitWidth += bitRange.upperBound - bitRange.lowerBound
    }
    return bitWidth
  }

  @inlinable @inline(__always)
  public static func insertBits(_ value: Storage, into storage: inout Storage) {
    storage[bits: Self.bitRanges] = value
  }

  @inlinable @inline(__always)
  public static func extractBits(from storage: Storage) -> Storage {
    storage[bits: Self.bitRanges]
  }
}

// MARK: - Bit field types for the macros

// The register macros declare each bit field as a typealias to
// `_MMIOBitField`, not as a new nominal type. A nominal type for each field
// makes the compiler emit metadata, a conformance, a witness table, and
// witness thunks for each field. `_MMIOBitField` shares that code for all
// fields, which makes registers much faster to compile.
//
// Do not use these types directly. Use the bit field macros.

/// A bit field whose bit ranges are in its generic arguments.
///
/// `Value` is the register type that declares the field. The fields of one
/// register cannot overlap, so `Value` and `BitRanges` together make each
/// field a distinct type: an extension on one field type does not apply to a
/// field with the same layout in another register.
///
/// `BitRanges` is a type-level list of one or more bit ranges. For example,
/// the list for bits `0..<2` and `8..<10` is:
///
/// ```swift
/// _MMIOBitFieldRange<0, 2,
///   _MMIOBitFieldRange<8, 10, _MMIOBitFieldRangeEnd>>
/// ```
///
/// - Important: Implementation detail of the bit field macros. Do not use
///   this type directly.
public enum _MMIOBitField<
  Value,
  FieldStorage: FixedWidthInteger & UnsignedInteger,
  FieldProjection: BitFieldProjectable,
  BitRanges: _MMIOBitFieldRanges
> {
  // Member types, as the field enums that the macros generated before had.
  // Generic parameters are not member types, so `Field.Storage` needs these.

  /// The underlying integer type of the register this bit field belongs to.
  public typealias Storage = FieldStorage

  /// The type this bit field projects to, or `Never` if it has no projection.
  public typealias Projection = FieldProjection

  /// The bit ranges this field occupies within the register, in order.
  @inlinable @inline(__always)
  public static var bitRanges: [Range<Int>] { BitRanges.bitRanges }

  @inlinable @inline(__always)
  public static var bitWidth: Int { BitRanges.bitWidth }

  @inlinable @inline(__always)
  public static func insertBits(_ value: Storage, into storage: inout Storage) {
    BitRanges.insertBits(value, into: &storage, shift: 0)
  }

  @inlinable @inline(__always)
  public static func extractBits(from storage: Storage) -> Storage {
    BitRanges.extractBits(from: storage, shift: 0)
  }

  @inlinable @inline(__always)
  public static func insert(_ value: Projection, into storage: inout Storage) {
    Self.preconditionMatchingBitWidth()
    Self.insertBits(value.storage(Storage.self), into: &storage)
  }

  @inlinable @inline(__always)
  public static func extract(from storage: Storage) -> Projection {
    Self.preconditionMatchingBitWidth()
    return Projection(storage: Self.extractBits(from: storage))
  }

  @inlinable @inline(__always)
  static func preconditionMatchingBitWidth(
    file: StaticString = #file,
    line: UInt = #line
  ) {
    #if hasFeature(Embedded)
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      Self.bitWidth == Projection.bitWidth,
      "Illegal projection of bit-field as type of differing bit-width",
      file: file,
      line: line)
    #else
    precondition(
      Self.bitWidth == Projection.bitWidth,
      """
      Illegal projection of \(Self.bitWidth) bit bit-field '\(Self.self)' \
      as \(Projection.bitWidth) bit type '\(Projection.self)'
      """,
      file: file,
      line: line)
    #endif
  }
}

// Members for a field with one bit range.
extension _MMIOBitField where BitRanges: _MMIOBitFieldSingleRange {
  /// The range of bits this field occupies within the register (e.g., `0..<4`
  /// for bits 0, 1, 2, 3).
  @inlinable @inline(__always)
  public static var bitRange: Range<Int> { BitRanges.bitRange }

  /// The offset of this field, representing the position of its least
  /// significant bit (LSB).
  @inlinable @inline(__always)
  public static var bitOffset: Int { BitRanges.bitRange.lowerBound }

  /// A bit mask representing the width of this field, right-aligned.
  ///
  /// For a field of `N` bits, this mask is `(1 << N) - 1`.
  @inlinable @inline(__always)
  public static var bitMask: Storage { (1 << Self.bitWidth) &- 1 }
}

/// A type-level list of bit ranges.
///
/// - Important: Implementation detail of the bit field macros. Do not use
///   this protocol directly.
public protocol _MMIOBitFieldRanges {
  /// The bit ranges in the list, in order.
  static var bitRanges: [Range<Int>] { get }

  /// The sum of the widths of the bit ranges in the list.
  static var bitWidth: Int { get }

  /// Inserts the bits of `value`, starting at bit `shift`, into the bit
  /// ranges of `storage`.
  ///
  /// When `shift` is `0`, traps if `value` does not fit in the bit ranges.
  static func insertBits<Storage: FixedWidthInteger>(
    _ value: Storage, into storage: inout Storage, shift: Int)

  /// Extracts the bit ranges of `storage` and shifts them left by `shift`.
  static func extractBits<Storage: FixedWidthInteger>(
    from storage: Storage, shift: Int
  ) -> Storage
}

/// The empty type-level list of bit ranges.
///
/// - Important: Implementation detail of the bit field macros. Do not use
///   this type directly.
public enum _MMIOBitFieldRangeEnd: _MMIOBitFieldRanges {
  @inlinable @inline(__always)
  public static var bitRanges: [Range<Int>] { [] }

  @inlinable @inline(__always)
  public static var bitWidth: Int { 0 }

  @inlinable @inline(__always)
  public static func insertBits<Storage: FixedWidthInteger>(
    _ value: Storage, into storage: inout Storage, shift: Int
  ) {}

  @inlinable @inline(__always)
  public static func extractBits<Storage: FixedWidthInteger>(
    from storage: Storage, shift: Int
  ) -> Storage { 0 }
}

/// A type-level list of bit ranges: the range `lowerBound..<upperBound`,
/// followed by the ranges in `Next`.
///
/// - Important: Implementation detail of the bit field macros. Do not use
///   this type directly.
public enum _MMIOBitFieldRange<
  let lowerBound: Int,
  let upperBound: Int,
  Next: _MMIOBitFieldRanges
>: _MMIOBitFieldRanges {
  @inlinable @inline(__always)
  public static var bitRanges: [Range<Int>] {
    [lowerBound..<upperBound] + Next.bitRanges
  }

  @inlinable @inline(__always)
  public static var bitWidth: Int {
    upperBound - lowerBound + Next.bitWidth
  }

  @inlinable @inline(__always)
  public static func insertBits<Storage: FixedWidthInteger>(
    _ value: Storage, into storage: inout Storage, shift: Int
  ) {
    // The checks of `Next` and `shift` fold away in optimized builds. In
    // unoptimized builds, they keep a field with one bit range as fast as a
    // direct `storage[bits:]` access.
    if Next.self == _MMIOBitFieldRangeEnd.self {
      // The last bit range. The subscript traps if the bits do not fit.
      if shift == 0 {
        storage[bits: lowerBound..<upperBound] = value
      } else {
        storage[bits: lowerBound..<upperBound] = value >> shift
      }
      return
    }
    if shift == 0 {
      // The first of more than one bit range.
      let bitMask: Storage = 1 << Self.bitWidth &- 1
      precondition((value & (~bitMask)) == 0)
    }
    let bitWidth = upperBound - lowerBound
    let bits = (value >> shift)[bits: 0..<bitWidth]
    storage[bits: lowerBound..<upperBound] = bits
    Next.insertBits(value, into: &storage, shift: shift + bitWidth)
  }

  @inlinable @inline(__always)
  public static func extractBits<Storage: FixedWidthInteger>(
    from storage: Storage, shift: Int
  ) -> Storage {
    let bits = storage[bits: lowerBound..<upperBound]
    if Next.self == _MMIOBitFieldRangeEnd.self {
      return shift == 0 ? bits : bits << shift
    }
    let bitWidth = upperBound - lowerBound
    return bits << shift
      | Next.extractBits(from: storage, shift: shift + bitWidth)
  }
}

/// A type-level list with exactly one bit range.
///
/// - Important: Implementation detail of the bit field macros. Do not use
///   this protocol directly.
public protocol _MMIOBitFieldSingleRange: _MMIOBitFieldRanges {
  /// The only bit range in the list.
  static var bitRange: Range<Int> { get }
}

extension _MMIOBitFieldRange: _MMIOBitFieldSingleRange
where Next == _MMIOBitFieldRangeEnd {
  @inlinable @inline(__always)
  public static var bitRange: Range<Int> { lowerBound..<upperBound }
}
