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

struct MMIOTracingInterposerTests {
  @Test func memory_load() {
    let interposer = MMIOTracingInterposer()
    interposer.memory[0x10] = 0x5a
    interposer.memory[0x11] = 0xa5
    let value: UInt16 = interposer.load(from: .init(bitPattern: 0x10)!)
    #expect(value == 0xa55a)

    assertMMIOInterposerTrace(
      interposer: interposer,
      trace: [
        .load(of: UInt16(0xa55a), from: 0x10)
      ])
  }

  @Test func memory_store() {
    let interposer = MMIOTracingInterposer()
    interposer.store(
      UInt16(0xa55a),
      to: .init(bitPattern: 0x10)!)
    #expect(interposer.memory[0x10] == 0x5a)
    #expect(interposer.memory[0x11] == 0xa5)
    assertMMIOInterposerTrace(
      interposer: interposer,
      trace: [
        .store(of: UInt16(0xa55a), to: 0x10)
      ])
  }

  @Test func assertMMIOAlignment_pass() {
    assertMMIOAlignment(pointer: UnsafePointer<UInt16>(bitPattern: 0x2)!)
  }

  @Test func assertMMIOAlignment_fail() {
    withKnownIssue("testing negative case") {
      assertMMIOAlignment(pointer: UnsafePointer<UInt16>(bitPattern: 0x1)!)
    }
  }

  @Test func assertMMIOInterposerTrace_pass() {
    let interposer = MMIOTracingInterposer()
    interposer.trace = [
      .store(of: UInt8(0xa5), to: 0x10),
      .load(of: UInt8(0x5a), from: 0x20),
    ]
    assertMMIOInterposerTrace(
      interposer: interposer,
      trace: [
        .store(of: UInt8(0xa5), to: 0x10),
        .load(of: UInt8(0x5a), from: 0x20),
      ])
  }

  @Test func assertMMIOInterposerTrace_fail() {
    let interposer = MMIOTracingInterposer()
    interposer.trace = [
      .store(of: UInt8(0xa5), to: 0x10),
      .load(of: UInt8(0x5a), from: 0x20),
    ]
    withKnownIssue("testing negative case") {
      assertMMIOInterposerTrace(
        interposer: interposer,
        trace: [
          .load(of: UInt8(0x5a), from: 0x20),
          .load(of: UInt8(0xa6), from: 0x30),
        ])
    }
  }
}
