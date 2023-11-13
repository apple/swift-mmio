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

import XCTest

@testable import MMIO

final class MMIOInterposableTests: XCTestCase {
  @RegisterBank
  struct Example {
    @RegisterBank(offset: 0x0)
    var regA: Register<RegA>
    @RegisterBank(offset: 0x4)
    var regB: Register<RegB>
  }

  @Register(bitWidth: 32)
  struct RegA {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var en: EN
    @Reserved(bits: 1..<32)
    var reserved0: Reserved0
  }

  @Register(bitWidth: 16)
  struct RegB {
    @ReadOnly(bits: 0..<1, as: Bool.self)
    var en: EN
    @WriteOnly(bits: 1..<2, as: Bool.self)
    var rst: RST
    @Reserved(bits: 3..<16)
    var reserved0: Reserved0
  }

  func test_registerBank_passesInterposerToChildren() {
    let interposer = MMIOTracingInterposer()
    let bank = Example(unsafeAddress: 0x1000, interposer: interposer)
    XCTAssertTrue(bank.interposer === bank.regA.interposer)
  }

  func test_tracingInterposer_producesExpectedTrace() {
    let interposer = MMIOTracingInterposer()
    let bank = Example(unsafeAddress: 0x1000, interposer: interposer)
    _ = bank.regA.read()
    bank.regA.modify { $0.en = true }
    bank.regA.write(unsafeBitCast(UInt32(0x5a5a_a5a5), to: RegA.ReadWrite.self))

    bank.regB.modify { r, w in
      w.rst = true
      w.raw.en = 1
    }
    bank.regB.modify { r, w in
      w.rst = false
    }
    XCTAssertMMIOInterposerTrace(
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
