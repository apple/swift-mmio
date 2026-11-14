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

  @Test func signedInteger_fromStorage() {
    #expect(Int8(5) == Int8(storage: UInt8(0x05)))
    #expect(Int8(-1) == Int8(storage: UInt8(0xff)))
    #expect(Int8.min == Int8(storage: UInt16(0x80)))
    #expect(Int16(-2) == Int16(storage: UInt16(0xfffe)))
    #expect(Int16.min == Int16(storage: UInt32(0x8000)))
    #expect(Int32(-1) == Int32(storage: UInt32(0xffff_ffff)))
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(Int32.min == Int32(storage: UInt64(0x8000_0000)))
    #expect(Int64(-1) == Int64(storage: UInt64(0xffff_ffff_ffff_ffff)))
    #endif
  }

  @Test func signedInteger_toStorage() {
    #expect(Int8(5).storage(UInt8.self) == 0x05)
    #expect(Int8(-1).storage(UInt8.self) == 0xff)
    #expect(Int8.min.storage(UInt16.self) == 0x80)
    #expect(Int16(-2).storage(UInt16.self) == 0xfffe)
    #expect(Int16.min.storage(UInt32.self) == 0x8000)
    #expect(Int32(-1).storage(UInt32.self) == 0xffff_ffff)
    #if arch(x86_64) || arch(arm64) || arch(arm64_32)
    #expect(Int32.min.storage(UInt64.self) == 0x8000_0000)
    #expect(Int64(-1).storage(UInt64.self) == 0xffff_ffff_ffff_ffff)
    #endif
  }

  private struct SignedBitField: ContiguousBitField {
    typealias Storage = UInt32
    typealias Projection = Int8
    static let bitRange = 8..<16
  }

  @Test func signedInteger_bitField() {
    #expect(SignedBitField.extract(from: 0x0000_7f00) == 127)
    #expect(SignedBitField.extract(from: 0xffff_80ff) == -128)

    var storage: UInt32 = 0xaaaa_00aa
    SignedBitField.insert(-2, into: &storage)
    #expect(storage == 0xaaaa_feaa)
    #expect(SignedBitField.extract(from: storage) == -2)
  }

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
}
