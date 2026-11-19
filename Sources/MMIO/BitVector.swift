//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A fixed-width sequence of bits.
///
/// A bit vector contains `width` bits. It has no sign and no numeric value.
/// You can set, clear, and combine its bits, but you cannot do arithmetic
/// with it. To use the bits as a number, convert them to an integer type.
/// Use ``Swift/FixedWidthInteger/init(zeroExtending:)`` to read the bits as
/// an unsigned value. Use ``Swift/FixedWidthInteger/init(signExtending:)`` to
/// read the bits as a signed value.
///
/// ## Conversions
///
/// Conversions follow two rules:
///
/// - An integer has a value. A conversion from an integer checks only that
///   no information is lost: the value must fit in `width` bits when you
///   read the bits as signed or as unsigned. For example, a `BitVector<4>`
///   accepts the values from `-8` through `15`. The exception is
///   ``init(truncatingIfNeeded:)``, which discards the high bits and does
///   not check them.
/// - Bits have no value. The label of a conversion to a wider type tells how
///   the conversion fills the new high bits: `zeroExtending` or
///   `signExtending`. The label of a conversion to a narrower type,
///   `truncating`, tells that the conversion discards bits. These checks use
///   only the widths, so an optimized build removes them. If a check fails,
///   the program traps at runtime.
///
/// ## Width
///
/// The value of `width` must be in the range `0...64` on 64-bit platforms
/// and arm64_32, and in the range `0...32` on other 32-bit platforms.
/// Creating a bit vector of a larger width traps.
///
/// ## Topics
///
/// ### Creating a Bit Vector
///
/// - ``zero``
/// - ``init()``
/// - ``init(integerLiteral:)``
///
/// ### Converting from Integers
///
/// - ``init(exactly:)``
/// - ``init(truncatingIfNeeded:)``
///
/// ### Converting from Bit Vectors
///
/// - ``init(zeroExtending:)``
/// - ``init(signExtending:)``
/// - ``init(truncating:)``
///
/// ### Converting to Integers
///
/// - ``Swift/FixedWidthInteger/init(zeroExtending:)``
/// - ``Swift/FixedWidthInteger/init(signExtending:)``
/// - ``Swift/FixedWidthInteger/init(truncating:)``
///
/// ### Bitwise Operators
///
/// - ``~(_:)``
/// - ``&(_:_:)``
/// - ``|(_:_:)``
/// - ``^(_:_:)``
/// - ``&=(_:_:)``
/// - ``|=(_:_:)``
/// - ``^=(_:_:)``
///
/// ### Describing a Bit Vector
///
/// - ``description``
///
/// ### Bit Field Projection
///
/// - ``bitWidth``
/// - ``init(storage:)``
/// - ``storage(_:)``
public struct BitVector<let width: Int>: Equatable, Hashable, Sendable {
  // Use 64-bit storage on architectures with 64-bit general purpose
  // registers. arm64_32 has 64-bit registers and 32-bit pointers.
  #if arch(x86_64) || arch(arm64) || arch(arm64_32)
  @usableFromInline
  internal typealias _Storage = UInt64
  @usableFromInline
  internal typealias _SignedStorage = Int64
  #else
  @usableFromInline
  internal typealias _Storage = UInt32
  @usableFromInline
  internal typealias _SignedStorage = Int32
  #endif

  // The bits of the vector. The bits at and above `width` are always zero.
  @usableFromInline
  internal var _storage: _Storage

  @inlinable @inline(__always)
  internal init(_unchecked storage: _Storage) {
    self._storage = storage
  }

  /// A mask of the `width` low bits of the storage.
  @inlinable @inline(__always)
  internal static var _mask: _Storage {
    precondition(
      0 <= width && width <= _Storage.bitWidth,
      "BitVector width is out of range for this platform")
    return (1 << width) &- 1
  }

  /// Returns `true` if `source` fits in `width` bits as a signed or an
  /// unsigned value.
  @inlinable @inline(__always)
  internal static func _fits<Source>(_ source: Source) -> Bool
  where Source: BinaryInteger {
    _ = Self._mask
    // The bits at and above `width` are zero: the value fits as unsigned.
    if source >> width == 0 { return true }
    // The bits at and above `width - 1` are one: the value fits as signed.
    return width > 0 && Source.isSigned && ~(source >> (width - 1)) == 0
  }

  /// The bits of the vector read as a signed value.
  @inlinable @inline(__always)
  internal var _signExtended: _SignedStorage {
    let shift = _Storage.bitWidth - width
    return _SignedStorage(truncatingIfNeeded: self._storage << shift) >> shift
  }

  /// A bit vector with all bits set to zero.
  ///
  /// ```swift
  /// var mask = BitVector<8>.zero   // 0b0000_0000
  /// mask |= 0b0000_1000            // 0b0000_1000
  /// ```
  @inlinable @inline(__always)
  public static var zero: Self {
    _ = Self._mask
    return Self(_unchecked: 0)
  }

  /// Creates a bit vector with all bits set to zero.
  ///
  /// This initializer gives the same value as ``zero``.
  ///
  /// ```swift
  /// var mask = BitVector<8>()   // 0b0000_0000
  /// mask |= 0b0000_1000         // 0b0000_1000
  /// ```
  @inlinable @inline(__always)
  public init() {
    self = .zero
  }
}

// MARK: - Integer to BitVector

extension BitVector {
  /// Creates a bit vector from the two's complement bits of an integer, or
  /// returns `nil` if `source` does not fit in `width` bits.
  ///
  /// The conversion keeps the low `width` bits of `source`. It returns `nil`
  /// if the discarded bits contain information. Thus you can always get the
  /// value of `source` back when you read the bits as signed or as unsigned:
  ///
  /// ```swift
  /// BitVector<8>(exactly: 200)    // 0b1100_1000
  /// BitVector<8>(exactly: -56)    // 0b1100_1000, the same bits
  /// BitVector<8>(exactly: 256)    // nil: 256 needs 9 bits.
  /// BitVector<8>(exactly: -129)   // nil: -129 needs 9 bits.
  /// ```
  ///
  /// A source of the same width always converts, signed or unsigned. The
  /// conversion extends a narrower source with its sign bit:
  ///
  /// ```swift
  /// BitVector<8>(exactly: Int8(-1))     // 0b1111_1111
  /// BitVector<8>(exactly: UInt8(255))   // 0b1111_1111
  /// BitVector<16>(exactly: Int8(-1))    // 0b1111_1111_1111_1111
  /// BitVector<16>(exactly: UInt8(255))  // 0b0000_0000_1111_1111
  /// ```
  ///
  /// If the value must fit, unwrap the result with `!`. The unwrap traps if
  /// the value does not fit:
  ///
  /// ```swift
  /// control.modify { $0.prescaler = BitVector(exactly: shift)! }
  /// ```
  ///
  /// To check a value before you write it to a field, use `guard`:
  ///
  /// ```swift
  /// guard let prescaler = BitVector<3>(exactly: requested) else {
  ///   throw ConfigurationError.prescalerOutOfRange
  /// }
  /// control.modify { $0.prescaler = prescaler }
  /// ```
  ///
  /// If `width` is 0, only `0` fits.
  ///
  /// - Parameter source: The integer to convert.
  @inlinable @inline(__always)
  public init?<Source>(exactly source: Source) where Source: BinaryInteger {
    guard Self._fits(source) else { return nil }
    self.init(truncatingIfNeeded: source)
  }

  /// Creates a bit vector from the low `width` bits of the two's complement
  /// value of an integer.
  ///
  /// This conversion never traps. It discards the bits of `source` at and
  /// above `width`:
  ///
  /// ```swift
  /// BitVector<4>(truncatingIfNeeded: 0x1F)   // 0b1111
  /// BitVector<4>(truncatingIfNeeded: 0x30)   // 0b0000
  /// BitVector<4>(truncatingIfNeeded: -9)     // 0b0111
  ///
  /// // Write the low 4 bits of a counter to a 4-bit field.
  /// control.modify { $0.sequence = BitVector(truncatingIfNeeded: counter) }
  /// ```
  ///
  /// - Parameter source: The integer to convert.
  @inlinable @inline(__always)
  public init<Source>(truncatingIfNeeded source: Source)
  where Source: BinaryInteger {
    self.init(_unchecked: _Storage(truncatingIfNeeded: source) & Self._mask)
  }
}

extension BitVector: ExpressibleByIntegerLiteral {
  /// Creates a bit vector from an integer literal.
  ///
  /// You usually use a literal to write a field. Binary literals show each
  /// bit of the field. A negative literal gives the two's complement bits, so
  /// `-1` sets all bits:
  ///
  /// ```swift
  /// let mode: BitVector<4> = 0b1010
  /// let all: BitVector<4> = -1        // 0b1111
  /// let wide: BitVector<64> = 0xFFFF_FFFF_FFFF_FFFF
  /// let bad: BitVector<4> = 16        // Traps: 16 needs 5 bits.
  ///
  /// control.modify { $0.prescaler = 0b101 }
  /// ```
  ///
  /// - Parameter value: The integer literal.
  ///
  /// - Precondition: `value` must fit in `width` bits as a signed or an
  ///   unsigned value.
  @inlinable @inline(__always)
  public init(integerLiteral value: StaticBigInt) {
    // Check the width before the literal, so that a bad width reports the
    // width error.
    let mask = Self._mask
    // `value.bitWidth` is the width of the value as a signed integer. An
    // unsigned value needs one bit less.
    precondition(
      value.bitWidth <= width
        || (value.signum() >= 0 && value.bitWidth - 1 <= width),
      "Not enough bits to represent the integer literal")
    // The storage can be wider than a word, for example on arm64_32, or
    // narrower, for example on riscv64.
    var storage: _Storage = 0
    let words = (_Storage.bitWidth + UInt.bitWidth - 1) / UInt.bitWidth
    for index in 0..<words {
      storage |=
        _Storage(truncatingIfNeeded: value[index]) << (index * UInt.bitWidth)
    }
    self.init(_unchecked: storage & mask)
  }
}

// MARK: - BitVector to BitVector

extension BitVector {
  /// Creates a bit vector from the low `width` bits of a wider bit vector.
  ///
  /// The conversion discards the high bits of `source`:
  ///
  /// ```swift
  /// let wide: BitVector<8> = 0b1010_0110
  /// BitVector<4>(truncating: wide)    // 0b0110
  /// BitVector<8>(truncating: wide)    // 0b1010_0110
  /// BitVector<16>(truncating: wide)   // Traps: 16 bits from 8 bits.
  /// ```
  ///
  /// - Parameter source: The bit vector to convert.
  ///
  /// - Precondition: `sourceWidth` must be equal to or greater than `width`.
  @inlinable @inline(__always)
  public init<let sourceWidth: Int>(truncating source: BitVector<sourceWidth>) {
    precondition(
      sourceWidth >= width, "Cannot truncate to a wider bit vector")
    self.init(truncatingIfNeeded: source._storage)
  }

  /// Creates a bit vector from the bits of a narrower bit vector, and sets
  /// the new high bits to zero.
  ///
  /// Use this initializer when the bits are an unsigned value:
  ///
  /// ```swift
  /// let narrow: BitVector<4> = 0b1010
  /// BitVector<8>(zeroExtending: narrow)   // 0b0000_1010
  /// BitVector<4>(zeroExtending: narrow)   // 0b1010
  /// BitVector<2>(zeroExtending: narrow)   // Traps: 2 bits from 4 bits.
  /// ```
  ///
  /// - Parameter source: The bit vector to convert.
  ///
  /// - Precondition: `sourceWidth` must be equal to or less than `width`.
  @inlinable @inline(__always)
  public init<let sourceWidth: Int>(
    zeroExtending source: BitVector<sourceWidth>
  ) {
    precondition(
      sourceWidth <= width, "Cannot extend to a narrower bit vector")
    // The bits of `source` at and above `sourceWidth` are already zero.
    _ = Self._mask
    self.init(_unchecked: source._storage)
  }

  /// Creates a bit vector from the bits of a narrower bit vector, and sets
  /// the new high bits to copies of the most significant bit of `source`.
  ///
  /// Use this initializer when the bits are a signed value:
  ///
  /// ```swift
  /// BitVector<8>(signExtending: BitVector<4>(0b1010))   // 0b1111_1010
  /// BitVector<8>(signExtending: BitVector<4>(0b0101))   // 0b0000_0101
  /// BitVector<2>(signExtending: BitVector<4>(0b0101))   // Traps.
  /// ```
  ///
  /// - Parameter source: The bit vector to convert.
  ///
  /// - Precondition: `sourceWidth` must be equal to or less than `width`.
  @inlinable @inline(__always)
  public init<let sourceWidth: Int>(
    signExtending source: BitVector<sourceWidth>
  ) {
    precondition(
      sourceWidth <= width, "Cannot extend to a narrower bit vector")
    self.init(truncatingIfNeeded: source._signExtended)
  }
}

// MARK: - BitVector to integer

extension FixedWidthInteger {
  /// Creates an integer from the unsigned value of the bits of a bit vector.
  ///
  /// Use this initializer to read a field as an unsigned value:
  ///
  /// ```swift
  /// let prescaler: BitVector<3> = 0b101
  /// UInt8(zeroExtending: prescaler)   // 5
  /// Int(zeroExtending: prescaler)     // 5
  ///
  /// let divisor = 1 << Int(zeroExtending: control.read().prescaler)
  /// ```
  ///
  /// The conversion sets the high bits to zero, so the result is always the
  /// unsigned value of the bits. A signed integer type uses one bit for the
  /// sign, so it must be wider than `source`:
  ///
  /// ```swift
  /// UInt8(zeroExtending: BitVector<8>(0xFF))   // 255
  /// Int16(zeroExtending: BitVector<8>(0xFF))   // 255
  /// Int8(zeroExtending: BitVector<8>(0xFF))    // Traps: 7 bits for the value.
  /// UInt8(zeroExtending: BitVector<9>(1))      // Traps: 8 bits from 9 bits.
  /// ```
  ///
  /// - Parameter source: The bit vector to convert.
  ///
  /// - Precondition: If `Self` is unsigned, `width` must be equal to or less
  ///   than `Self.bitWidth`. If `Self` is signed, `width` must be less than
  ///   `Self.bitWidth`.
  @inlinable @inline(__always)
  public init<let width: Int>(zeroExtending source: BitVector<width>) {
    // A signed integer uses one bit for the sign.
    precondition(
      width <= Self.bitWidth - (Self.isSigned ? 1 : 0),
      "Not enough bits to represent the unsigned value")
    self.init(truncatingIfNeeded: source._storage)
  }

  /// Creates an integer from the low `Self.bitWidth` bits of a bit vector.
  ///
  /// The conversion discards the high bits of `source`, and then reads the
  /// remaining bits as `Self`. This is the only conversion from a bit vector
  /// to an integer that can change the value of the bits:
  ///
  /// ```swift
  /// let address: BitVector<12> = 0xABC
  /// UInt8(truncating: address)    // 0xBC
  /// Int8(truncating: address)     // -68, the bits 0xBC
  /// UInt16(truncating: address)   // Traps: 16 bits from 12 bits.
  /// ```
  ///
  /// - Parameter source: The bit vector to convert.
  ///
  /// - Precondition: `width` must be equal to or greater than
  ///   `Self.bitWidth`.
  @inlinable @inline(__always)
  public init<let width: Int>(truncating source: BitVector<width>) {
    precondition(
      width >= Self.bitWidth, "Cannot truncate to a wider integer type")
    self.init(truncatingIfNeeded: source._storage)
  }
}

extension FixedWidthInteger where Self: SignedInteger {
  /// Creates an integer from the signed value of the bits of a bit vector.
  ///
  /// Use this initializer to read a field as a signed value, for example a
  /// calibration offset in two's complement:
  ///
  /// ```swift
  /// let trim: BitVector<4> = 0b1110
  /// Int8(signExtending: trim)    // -2
  /// Int(signExtending: trim)     // -2
  ///
  /// let offset = Int(signExtending: sensor.read().trim)
  /// ```
  ///
  /// The conversion sets the high bits to copies of the most significant bit
  /// of `source`, so the result is always the signed value of the bits. This
  /// initializer is available only on signed integer types. To get the bits
  /// of a signed value in an unsigned type, convert the signed result:
  ///
  /// ```swift
  /// UInt8(bitPattern: Int8(signExtending: trim))   // 0b1111_1110
  /// ```
  ///
  /// - Parameter source: The bit vector to convert.
  ///
  /// - Precondition: `width` must be equal to or less than `Self.bitWidth`.
  @inlinable @inline(__always)
  public init<let width: Int>(signExtending source: BitVector<width>) {
    precondition(
      width <= Self.bitWidth, "Cannot extend to a narrower integer type")
    self.init(truncatingIfNeeded: source._signExtended)
  }
}

// MARK: - Bitwise operations

extension BitVector {
  /// Returns a bit vector with each bit of `vector` inverted.
  ///
  /// Only the `width` bits of the vector change:
  ///
  /// ```swift
  /// ~BitVector<4>(0b1010)   // 0b0101
  /// ~BitVector<4>.zero     // 0b1111
  /// ```
  ///
  /// - Parameter vector: The bit vector to invert.
  ///
  /// - Returns: A bit vector with each bit of `vector` inverted.
  @inlinable @inline(__always)
  public static prefix func ~ (vector: Self) -> Self {
    Self(_unchecked: ~vector._storage & Self._mask)
  }

  /// Returns a bit vector with the bits that are set in both `lhs` and
  /// `rhs`.
  ///
  /// Use this operator to clear bits or to test bits with a mask:
  ///
  /// ```swift
  /// let flags: BitVector<4> = 0b1100
  /// flags & 0b1010            // 0b1000
  /// flags & 0b0011 == 0       // true: bits 0 and 1 are clear.
  /// ```
  @inlinable @inline(__always)
  public static func & (lhs: Self, rhs: Self) -> Self {
    Self(_unchecked: lhs._storage & rhs._storage)
  }

  /// Returns a bit vector with the bits that are set in `lhs`, in `rhs`, or
  /// in both.
  ///
  /// Use this operator to set bits:
  ///
  /// ```swift
  /// let flags: BitVector<4> = 0b1100
  /// flags | 0b1010            // 0b1110
  /// ```
  @inlinable @inline(__always)
  public static func | (lhs: Self, rhs: Self) -> Self {
    Self(_unchecked: lhs._storage | rhs._storage)
  }

  /// Returns a bit vector with the bits that are set in `lhs` or in `rhs`,
  /// but not in both.
  ///
  /// Use this operator to toggle bits, or to find the bits that are
  /// different:
  ///
  /// ```swift
  /// let flags: BitVector<4> = 0b1100
  /// flags ^ 0b1010            // 0b0110
  /// ```
  @inlinable @inline(__always)
  public static func ^ (lhs: Self, rhs: Self) -> Self {
    Self(_unchecked: lhs._storage ^ rhs._storage)
  }

  /// Clears the bits of `lhs` that are not set in `rhs`.
  ///
  /// ```swift
  /// var flags: BitVector<4> = 0b1101
  /// flags &= ~0b0100          // 0b1001
  /// ```
  @inlinable @inline(__always)
  public static func &= (lhs: inout Self, rhs: Self) {
    lhs = lhs & rhs
  }

  /// Sets the bits of `lhs` that are set in `rhs`.
  ///
  /// ```swift
  /// var flags: BitVector<4> = 0b1000
  /// flags |= 0b0001           // 0b1001
  /// ```
  @inlinable @inline(__always)
  public static func |= (lhs: inout Self, rhs: Self) {
    lhs = lhs | rhs
  }

  /// Toggles the bits of `lhs` that are set in `rhs`.
  ///
  /// ```swift
  /// var flags: BitVector<4> = 0b1001
  /// flags ^= 0b1111           // 0b0110
  /// ```
  @inlinable @inline(__always)
  public static func ^= (lhs: inout Self, rhs: Self) {
    lhs = lhs ^ rhs
  }
}

// MARK: - Description

extension BitVector: CustomStringConvertible {
  /// A binary literal of the bits, with zeros added on the left to show
  /// `width` digits.
  ///
  /// ```swift
  /// print(BitVector<4>(0b0101))   // Prints "0b0101"
  /// print(BitVector<8>(-1))       // Prints "0b11111111"
  /// ```
  @inlinable
  public var description: String {
    let digits = String(self._storage, radix: 2)
    let padding = String(repeating: "0", count: max(0, width - digits.count))
    return "0b" + padding + digits
  }
}

// MARK: - Bit field projection

extension BitVector: BitFieldProjectable {
  /// The number of bits in the vector.
  ///
  /// This value is equal to `width`. The bit field macros use it to make sure
  /// that the projection has the same width as its field.
  ///
  /// ```swift
  /// BitVector<12>.bitWidth   // 12
  /// ```
  @inlinable @inline(__always)
  public static var bitWidth: Int { width }

  /// Creates a bit vector from the value of a bit field.
  ///
  /// The bit field macros call this initializer when you read a field.
  /// Before the call, the macros shift and mask the value of the field to
  /// `width` bits. Thus the conversion does not lose information:
  ///
  /// ```swift
  /// BitVector<3>(storage: UInt32(0b101))   // 0b101
  /// ```
  ///
  /// - Parameter storage: The value of the field.
  @inlinable @inline(__always)
  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger {
    self.init(truncatingIfNeeded: storage)
  }

  /// Returns the bits of the vector as the storage type of a register, with
  /// the high bits set to zero.
  ///
  /// The bit field macros call this method when you write a field. A field
  /// is never wider than its register, so `width` is always equal to or less
  /// than the width of `Storage`:
  ///
  /// ```swift
  /// BitVector<3>(0b101).storage(UInt32.self)   // 0b101
  /// ```
  ///
  /// - Parameter type: The storage type of the register.
  ///
  /// - Returns: The bits of the vector, zero-extended to `Storage`.
  @inlinable @inline(__always)
  public func storage<Storage>(_ type: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger {
    precondition(
      width <= Storage.bitWidth, "Cannot extend to a narrower integer type")
    // The mask tells the optimizer that the bits at and above `width` are
    // zero, so it can remove the range check when the field is written.
    return Storage(truncatingIfNeeded: self._storage & Self._mask)
  }

}
