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

// Explore bit field refactor:
// * requires variadic pack iteration
// * requires metadata-less variadic packs
// - protocol BitField with (least|most) significant bit requirements
// - FixedWidthInteger.subscript[(variadic T: BitField)] -> Storage

extension FixedWidthInteger {
  @inlinable @inline(__always)
  static func bitRangeWithinBounds(bits bitRange: Range<Int>) -> Bool {
    bitRange.lowerBound >= 0 && bitRange.upperBound <= Self.bitWidth
  }

  @inlinable @inline(__always)
  subscript(bits bitRange: Range<Int>) -> Self {
    @inlinable @inline(__always) get {
      precondition(Self.bitRangeWithinBounds(bits: bitRange))
      let bitWidth = bitRange.upperBound - bitRange.lowerBound
      let bitMask: Self = 1 << bitWidth &- 1
      return (self >> bitRange.lowerBound) & bitMask
    }

    @inlinable @inline(__always) set {
      precondition(Self.bitRangeWithinBounds(bits: bitRange))
      let bitWidth = bitRange.upperBound - bitRange.lowerBound
      let bitMask: Self = 1 << bitWidth &- 1
      self &= ~(bitMask << bitRange.lowerBound)
      precondition((newValue & (~bitMask)) == 0)
      self |= (newValue & bitMask) << bitRange.lowerBound
    }
  }
}

extension FixedWidthInteger {
  @inlinable @inline(__always)
  static func bitRangesCoalesced(bits bitRanges: [Range<Int>]) -> Bool {
    let bitRanges = bitRanges.sorted { $0.lowerBound < $1.lowerBound }
    var lowerBound = -1
    for bitRange in bitRanges {
      // Specifically ensure that the bit ranges dont overlap, e.g. the
      // following ranges are not valid: 0..<1, 0..<2. This is to ensure ranges
      // are coalesced before iterating reduce the number of mask and shift
      // operations needed.
      guard lowerBound <= bitRange.lowerBound else { return false }
      lowerBound = bitRange.upperBound
    }
    return true
  }

  @inlinable @inline(__always)
  subscript(bits bitRanges: [Range<Int>]) -> Self {
    @inlinable @inline(__always) get {
      precondition(Self.bitRangesCoalesced(bits: bitRanges))

      var currentShift = 0
      var value: Self = 0
      for bitRange in bitRanges {
        precondition(Self.bitRangeWithinBounds(bits: bitRange))
        let bitWidth = bitRange.upperBound - bitRange.lowerBound
        let bitMask: Self = 1 << bitWidth &- 1
        let valueSlice = (self >> bitRange.lowerBound) & bitMask
        value |= valueSlice << currentShift
        currentShift += bitWidth
      }
      return value
    }

    @inlinable @inline(__always) set {
      precondition(Self.bitRangesCoalesced(bits: bitRanges))
      var fullBitWidth = 0
      for bitRange in bitRanges {
        fullBitWidth += bitRange.upperBound - bitRange.lowerBound
      }
      let fullBitMask: Self = 1 << fullBitWidth &- 1
      precondition((newValue & (~fullBitMask)) == 0)

      var newValue = newValue
      for bitRange in bitRanges {
        precondition(Self.bitRangeWithinBounds(bits: bitRange))
        let bitWidth = bitRange.upperBound - bitRange.lowerBound
        let bitMask: Self = 1 << bitWidth &- 1
        self &= ~(bitMask << bitRange.lowerBound)
        self |= (newValue & bitMask) << bitRange.lowerBound
        newValue >>= bitWidth
      }
    }
  }
}

public protocol BitField {
  associatedtype Storage: FixedWidthInteger & UnsignedInteger
  associatedtype Projection: BitFieldProjectable

  static var bitWidth: Int { get }

  static func insertBits(_ value: Storage, into storage: inout Storage)
  static func extractBits(from storage: Storage) -> Storage

  static func insert(_ value: Projection, into storage: inout Storage)
  static func extract(from storage: Storage) -> Projection
}

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

public protocol ContiguousBitField: BitField {
  static var bitRange: Range<Int> { get }
  static var bitOffset: Int { get }
  static var bitMask: Storage { get }
}

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

public protocol DiscontiguousBitField: BitField {
  /// - Precondition: Bit bitRanges must not overlap and must be sorted by from
  /// lowest to highest bit index
  static var bitRanges: [Range<Int>] { get }
}

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
