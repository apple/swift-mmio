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

import Testing

@testable import MMIO

struct BitFieldProjectableTests {
  /// Checks that `Field` extracts `value` from `storage`, and that inserting
  /// `value` writes the field bits of `storage` and keeps the other bits.
  private func expectBitField<Field: ContiguousBitField>(
    _: Field.Type,
    _ value: Field.Projection,
    _ storage: Field.Storage,
    sourceLocation: SourceLocation = #_sourceLocation
  ) where Field.Projection: Equatable {
    #expect(
      Field.extract(from: storage) == value, sourceLocation: sourceLocation)
    var inserted = storage
    Field.insertBits(0, into: &inserted)
    Field.insert(value, into: &inserted)
    #expect(inserted == storage, sourceLocation: sourceLocation)
  }
}

extension BitFieldProjectableTests {
  @Test func bool_fromStorage() {
    #expect(false == Bool(storage: UInt8(0x0)))
    #expect(false == Bool(storage: UInt16(0x0)))
    #expect(false == Bool(storage: UInt32(0x0)))
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(false == Bool(storage: UInt64(0x0)))
    #endif

    #expect(true == Bool(storage: UInt8(0x1)))
    #expect(true == Bool(storage: UInt16(0x1)))
    #expect(true == Bool(storage: UInt32(0x1)))
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(true == Bool(storage: UInt64(0x1)))
    #endif
  }

  @Test func bool_toStorage() {
    #expect(false.storage(UInt8.self) == 0x0)
    #expect(false.storage(UInt16.self) == 0x0)
    #expect(false.storage(UInt32.self) == 0x0)
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(false.storage(UInt64.self) == 0x0)
    #endif

    #expect(true.storage(UInt8.self) == 0x1)
    #expect(true.storage(UInt16.self) == 0x1)
    #expect(true.storage(UInt32.self) == 0x1)
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(true.storage(UInt64.self) == 0x1)
    #endif
  }

  private struct BoolField: ContiguousBitField {
    typealias Storage = UInt8
    typealias Projection = Bool
    static let bitRange = 4..<5
  }

  @Test func bool_bitField() {
    expectBitField(BoolField.self, false, 0xaa)
    expectBitField(BoolField.self, true, 0xba)
  }
}

extension BitFieldProjectableTests {
  @Test func unsignedInteger_fromStorage() {
    #expect(UInt8.min == UInt8(storage: UInt8(0x00)))
    #expect(UInt8(1) == UInt8(storage: UInt8(0x01)))
    #expect(UInt8.max == UInt8(storage: UInt8(0xff)))

    #expect(UInt16.min == UInt16(storage: UInt16(0x0000)))
    #expect(UInt16(1) == UInt16(storage: UInt16(0x0001)))
    #expect(UInt16.max == UInt16(storage: UInt16(0xffff)))

    #expect(UInt32.min == UInt32(storage: UInt32(0x0000_0000)))
    #expect(UInt32(1) == UInt32(storage: UInt32(0x0000_0001)))
    #expect(UInt32.max == UInt32(storage: UInt32(0xffff_ffff)))

    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(UInt64.min == UInt64(storage: UInt64(0x0000_0000_0000_0000)))
    #expect(UInt64(1) == UInt64(storage: UInt64(0x0000_0000_0000_0001)))
    #expect(UInt64.max == UInt64(storage: UInt64(0xffff_ffff_ffff_ffff)))
    #endif
  }

  @Test func unsignedInteger_toStorage() {
    #expect(UInt8.min.storage(UInt8.self) == 0x00)
    #expect(UInt8(1).storage(UInt8.self) == 0x01)
    #expect(UInt8.max.storage(UInt8.self) == 0xff)

    #expect(UInt16.min.storage(UInt16.self) == 0x0000)
    #expect(UInt16(1).storage(UInt16.self) == 0x0001)
    #expect(UInt16.max.storage(UInt16.self) == 0xffff)

    #expect(UInt32.min.storage(UInt32.self) == 0x0000_0000)
    #expect(UInt32(1).storage(UInt32.self) == 0x0000_0001)
    #expect(UInt32.max.storage(UInt32.self) == 0xffff_ffff)

    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(UInt64.min.storage(UInt64.self) == 0x0000_0000_0000_0000)
    #expect(UInt64(1).storage(UInt64.self) == 0x0000_0000_0000_0001)
    #expect(UInt64.max.storage(UInt64.self) == 0xffff_ffff_ffff_ffff)
    #endif
  }

  private struct UInt8Field: ContiguousBitField {
    typealias Storage = UInt16
    typealias Projection = UInt8
    static let bitRange = 4..<12
  }

  private struct UInt16Field: ContiguousBitField {
    typealias Storage = UInt32
    typealias Projection = UInt16
    static let bitRange = 8..<24
  }

  private struct UInt32Field: ContiguousBitField {
    typealias Storage = UInt64
    typealias Projection = UInt32
    static let bitRange = 16..<48
  }

  private struct UInt64Field: ContiguousBitField {
    typealias Storage = UInt64
    typealias Projection = UInt64
    static let bitRange = 0..<64
  }

  @Test func unsignedInteger_bitField() {
    expectBitField(UInt8Field.self, UInt8.min, 0xa00a)
    expectBitField(UInt8Field.self, UInt8(1), 0xa01a)
    expectBitField(UInt8Field.self, UInt8.max, 0xaffa)

    expectBitField(UInt16Field.self, UInt16.min, 0xaa00_00aa)
    expectBitField(UInt16Field.self, UInt16(1), 0xaa00_01aa)
    expectBitField(UInt16Field.self, UInt16.max, 0xaaff_ffaa)

    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    expectBitField(UInt32Field.self, UInt32.min, 0xaaaa_0000_0000_aaaa)
    expectBitField(UInt32Field.self, UInt32(1), 0xaaaa_0000_0001_aaaa)
    expectBitField(UInt32Field.self, UInt32.max, 0xaaaa_ffff_ffff_aaaa)

    expectBitField(UInt64Field.self, UInt64.min, 0x0000_0000_0000_0000)
    expectBitField(UInt64Field.self, UInt64(1), 0x0000_0000_0000_0001)
    expectBitField(UInt64Field.self, UInt64.max, 0xffff_ffff_ffff_ffff)
    #endif
  }
}

extension BitFieldProjectableTests {
  @Test func signedInteger_fromStorage() {
    #expect(Int8.min == Int8(storage: UInt8(0x80)))
    #expect(Int8(-1) == Int8(storage: UInt8(0xff)))
    #expect(Int8(0) == Int8(storage: UInt8(0x00)))
    #expect(Int8.max == Int8(storage: UInt8(0x7f)))

    #expect(Int16.min == Int16(storage: UInt16(0x8000)))
    #expect(Int16(-1) == Int16(storage: UInt16(0xffff)))
    #expect(Int16(0) == Int16(storage: UInt16(0x0000)))
    #expect(Int16.max == Int16(storage: UInt16(0x7fff)))

    #expect(Int32.min == Int32(storage: UInt32(0x8000_0000)))
    #expect(Int32(-1) == Int32(storage: UInt32(0xffff_ffff)))
    #expect(Int32(0) == Int32(storage: UInt32(0x0000_0000)))
    #expect(Int32.max == Int32(storage: UInt32(0x7fff_ffff)))

    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(Int64.min == Int64(storage: UInt64(0x8000_0000_0000_0000)))
    #expect(Int64(-1) == Int64(storage: UInt64(0xffff_ffff_ffff_ffff)))
    #expect(Int64(0) == Int64(storage: UInt64(0x0000_0000_0000_0000)))
    #expect(Int64.max == Int64(storage: UInt64(0x7fff_ffff_ffff_ffff)))
    #endif
  }

  @Test func signedInteger_toStorage() {
    #expect(Int8.min.storage(UInt8.self) == 0x80)
    #expect(Int8(-1).storage(UInt8.self) == 0xff)
    #expect(Int8(0).storage(UInt8.self) == 0x00)
    #expect(Int8.max.storage(UInt8.self) == 0x7f)

    #expect(Int16.min.storage(UInt16.self) == 0x8000)
    #expect(Int16(-1).storage(UInt16.self) == 0xffff)
    #expect(Int16(0).storage(UInt16.self) == 0x0000)
    #expect(Int16.max.storage(UInt16.self) == 0x7fff)

    #expect(Int32.min.storage(UInt32.self) == 0x8000_0000)
    #expect(Int32(-1).storage(UInt32.self) == 0xffff_ffff)
    #expect(Int32(0).storage(UInt32.self) == 0x0000_0000)
    #expect(Int32.max.storage(UInt32.self) == 0x7fff_ffff)

    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(Int64.min.storage(UInt64.self) == 0x8000_0000_0000_0000)
    #expect(Int64(-1).storage(UInt64.self) == 0xffff_ffff_ffff_ffff)
    #expect(Int64(0).storage(UInt64.self) == 0x0000_0000_0000_0000)
    #expect(Int64.max.storage(UInt64.self) == 0x7fff_ffff_ffff_ffff)
    #endif
  }

  private struct Int8Field: ContiguousBitField {
    typealias Storage = UInt16
    typealias Projection = Int8
    static let bitRange = 4..<12
  }

  private struct Int16Field: ContiguousBitField {
    typealias Storage = UInt32
    typealias Projection = Int16
    static let bitRange = 8..<24
  }

  private struct Int32Field: ContiguousBitField {
    typealias Storage = UInt64
    typealias Projection = Int32
    static let bitRange = 16..<48
  }

  private struct Int64Field: ContiguousBitField {
    typealias Storage = UInt64
    typealias Projection = Int64
    static let bitRange = 0..<64
  }

  @Test func signedInteger_bitField() {
    expectBitField(Int8Field.self, Int8.min, 0xa80a)
    expectBitField(Int8Field.self, Int8(-1), 0xaffa)
    expectBitField(Int8Field.self, Int8(0), 0xa00a)
    expectBitField(Int8Field.self, Int8.max, 0xa7fa)

    expectBitField(Int16Field.self, Int16.min, 0xaa80_00aa)
    expectBitField(Int16Field.self, Int16(-1), 0xaaff_ffaa)
    expectBitField(Int16Field.self, Int16(0), 0xaa00_00aa)
    expectBitField(Int16Field.self, Int16.max, 0xaa7f_ffaa)

    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    expectBitField(Int32Field.self, Int32.min, 0xaaaa_8000_0000_aaaa)
    expectBitField(Int32Field.self, Int32(-1), 0xaaaa_ffff_ffff_aaaa)
    expectBitField(Int32Field.self, Int32(0), 0xaaaa_0000_0000_aaaa)
    expectBitField(Int32Field.self, Int32.max, 0xaaaa_7fff_ffff_aaaa)

    expectBitField(Int64Field.self, Int64.min, 0x8000_0000_0000_0000)
    expectBitField(Int64Field.self, Int64(-1), 0xffff_ffff_ffff_ffff)
    expectBitField(Int64Field.self, Int64(0), 0x0000_0000_0000_0000)
    expectBitField(Int64Field.self, Int64.max, 0x7fff_ffff_ffff_ffff)
    #endif
  }
}

extension BitFieldProjectableTests {
  private enum Example: UInt8, BitFieldProjectable, CaseIterable {
    static let bitWidth = 2
    case a = 0x0
    case b = 0x1
    case c = 0x3
    case d = 0x4
  }

  @Test func rawRepresentable_fromStorage() {
    for `case` in Example.allCases {
      #expect(`case` == Example(storage: UInt8(`case`.rawValue)))
      #expect(`case` == Example(storage: UInt16(`case`.rawValue)))
      #expect(`case` == Example(storage: UInt32(`case`.rawValue)))
      #if arch(x86_64) || arch(arm64) || arch(arm64_32)
      #expect(`case` == Example(storage: UInt64(`case`.rawValue)))
      #endif
    }
  }

  @Test func rawRepresentable_toStorage() {
    for `case` in Example.allCases {
      #expect(`case`.storage(UInt8.self) == UInt8(`case`.rawValue))
      #expect(`case`.storage(UInt16.self) == UInt16(`case`.rawValue))
      #expect(`case`.storage(UInt32.self) == UInt32(`case`.rawValue))
      #if arch(x86_64) || arch(arm64) || arch(arm64_32)
      #expect(`case`.storage(UInt64.self) == UInt64(`case`.rawValue))
      #endif
    }
  }

  private enum SignedExample: Int8, BitFieldProjectable {
    static let bitWidth = 2
    case minusTwo = -2
    case minusOne = -1
    case zero = 0
    case one = 1
  }

  private enum FullWidthSignedExample: Int8, BitFieldProjectable {
    static let bitWidth = 8
    case lowest = -128
    case highest = 127
  }

  @Test func signedRawRepresentable_fromStorage() {
    #expect(SignedExample.minusTwo == SignedExample(storage: UInt8(0b10)))
    #expect(SignedExample.minusOne == SignedExample(storage: UInt8(0b11)))
    #expect(SignedExample.zero == SignedExample(storage: UInt8(0b00)))
    #expect(SignedExample.one == SignedExample(storage: UInt8(0b01)))

    #expect(
      FullWidthSignedExample.lowest
        == FullWidthSignedExample(storage: UInt16(0x0080)))
    #expect(
      FullWidthSignedExample.highest
        == FullWidthSignedExample(storage: UInt16(0x007f)))
  }

  @Test func signedRawRepresentable_toStorage() {
    #expect(SignedExample.minusTwo.storage(UInt8.self) == 0b10)
    #expect(SignedExample.minusOne.storage(UInt8.self) == 0b11)
    #expect(SignedExample.zero.storage(UInt8.self) == 0b00)
    #expect(SignedExample.one.storage(UInt8.self) == 0b01)

    #expect(FullWidthSignedExample.lowest.storage(UInt16.self) == 0x0080)
    #expect(FullWidthSignedExample.highest.storage(UInt16.self) == 0x007f)
  }

  private struct SignedExampleField: ContiguousBitField {
    typealias Storage = UInt8
    typealias Projection = SignedExample
    static let bitRange = 3..<5
  }

  @Test func signedRawRepresentable_bitField() {
    expectBitField(SignedExampleField.self, .minusTwo, 0xb2)
    expectBitField(SignedExampleField.self, .minusOne, 0xba)
    expectBitField(SignedExampleField.self, .zero, 0xa2)
    expectBitField(SignedExampleField.self, .one, 0xaa)
  }
}
