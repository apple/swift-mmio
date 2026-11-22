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

@testable import MMIOInterposable

struct MMIOInterposableTests {
  @RegisterBlock
  struct Example {
    @RegisterBlock(offset: 0x0)
    var regA: Register<RegA>
    @RegisterBlock(offset: 0x4)
    var regB: Register<RegB>
  }

  @Register(bitWidth: 32)
  struct RegA {
    @ReadWrite(bits: 0, as: Bool.self)
    var en: EN
    @Reserved(bits: 1..<32)
    var reserved0: Reserved0
  }

  @Register(bitWidth: 16)
  struct RegB {
    @ReadOnly(bits: 0, as: Bool.self)
    var en: EN
    @WriteOnly(bits: 1, as: Bool.self)
    var rst: RST
    @Reserved(bits: 3..<16)
    var reserved0: Reserved0
  }

  @Register(bitWidth: 16, reset: 0x8002)
  struct WriteOnlyRegister {
    @WriteOnly(bits: ..., as: UInt16.self)
    var command: COMMAND
  }

  @Test func reset_writesDeclaredValueWithoutReading() {
    let interposer = MMIOTracingInterposer()
    let register = Register<WriteOnlyRegister>(
      unsafeAddress: 0x1000, interposer: interposer)

    register.reset()

    assertMMIOInterposerTrace(
      interposer: interposer,
      trace: [.store(of: UInt16(0x8002), to: 0x1000)])
  }

  // 0x8002 sets bit 1 (in the writable field) and bit 15 (in the reserved
  // field). The store must keep the reserved bits from the reset pattern.
  @Register(bitWidth: 16, reset: 0x8002)
  struct ReadWriteReservedRegister {
    @ReadWrite(bits: 0..<2, as: UInt16.self)
    var value: VALUE
    @Reserved(bits: 2..<16)
    var reserved0: Reserved0
  }

  @Test func reset_storesReservedBitsFromDeclaredValue() {
    let interposer = MMIOTracingInterposer()
    let register = Register<ReadWriteReservedRegister>(
      unsafeAddress: 0x1000, interposer: interposer)

    register.reset()

    assertMMIOInterposerTrace(
      interposer: interposer,
      trace: [.store(of: UInt16(0x8002), to: 0x1000)])
  }

  @Test func registerBlock_passesInterposerToChildren() {
    let interposer = MMIOTracingInterposer()
    let example = Example(unsafeAddress: 0x1000, interposer: interposer)
    #expect(example.interposer === example.regA.interposer)
  }

  @Test func tracingInterposer_producesExpectedTrace() {
    let interposer = MMIOTracingInterposer()
    let example = Example(unsafeAddress: 0x1000, interposer: interposer)
    _ = example.regA.read()
    example.regA.modify { $0.en = true }
    example.regA.write(.init(.init(0x5a5a_a5a5)))

    example.regB.modify { r, w in
      w.rst = true
      w.raw.en = 1
    }
    example.regB.modify { r, w in
      w.rst = false
    }
    assertMMIOInterposerTrace(
      interposer: interposer,
      trace: [
        .load(of: UInt32(0), from: 0x1000),
        .load(of: UInt32(0), from: 0x1000),
        .store(of: UInt32(1), to: 0x1000),
        .store(of: UInt32(0x5a5a_a5a5), to: 0x1000),
        .load(of: UInt16(0x0000), from: 0x1004),
        .store(of: UInt16(0x0003), to: 0x1004),
        .load(of: UInt16(0x0003), from: 0x1004),
        .store(of: UInt16(0x0001), to: 0x1004),
      ])
  }
}
