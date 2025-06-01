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

struct MMIOTracingInterposerEventTests {
  @Test func load() {
    #expect(
      MMIOTracingInterposerEvent.load(of: UInt8(1), from: 0x10)
        == MMIOTracingInterposerEvent(
          load: true, address: 0x10, size: 8, value: 1))
    #expect(
      MMIOTracingInterposerEvent.load(of: UInt16(2), from: 0x10)
        == MMIOTracingInterposerEvent(
          load: true, address: 0x10, size: 16, value: 2))
    #expect(
      MMIOTracingInterposerEvent.load(of: UInt32(3), from: 0x10)
        == MMIOTracingInterposerEvent(
          load: true, address: 0x10, size: 32, value: 3))
    #expect(
      MMIOTracingInterposerEvent.load(of: UInt64(4), from: 0x10)
        == MMIOTracingInterposerEvent(
          load: true, address: 0x10, size: 64, value: 4))
  }

  @Test func store() {
    #expect(
      MMIOTracingInterposerEvent.store(of: UInt8(1), to: 0x10)
        == MMIOTracingInterposerEvent(
          load: false, address: 0x10, size: 8, value: 1))
    #expect(
      MMIOTracingInterposerEvent.store(of: UInt16(2), to: 0x10)
        == MMIOTracingInterposerEvent(
          load: false, address: 0x10, size: 16, value: 2)
    )
    #expect(
      MMIOTracingInterposerEvent.store(of: UInt32(3), to: 0x10)
        == MMIOTracingInterposerEvent(
          load: false, address: 0x10, size: 32, value: 3)
    )
    #expect(
      MMIOTracingInterposerEvent.store(of: UInt64(4), to: 0x10)
        == MMIOTracingInterposerEvent(
          load: false, address: 0x10, size: 64, value: 4)
    )
  }

  @Test func description() {
    #expect(
      MMIOTracingInterposerEvent.load(of: UInt8(1), from: 0x10).description
        == "m[0x0000_0000_0000_0010] -> 0x01")
    #expect(
      MMIOTracingInterposerEvent.load(of: UInt16(2), from: 0x10).description
        == "m[0x0000_0000_0000_0010] -> 0x0002")
    #expect(
      MMIOTracingInterposerEvent.load(of: UInt32(3), from: 0x10).description
        == "m[0x0000_0000_0000_0010] -> 0x0000_0003")
    #expect(
      MMIOTracingInterposerEvent.load(of: UInt64(4), from: 0x10).description
        == "m[0x0000_0000_0000_0010] -> 0x0000_0000_0000_0004")

    #expect(
      MMIOTracingInterposerEvent.store(of: UInt8(1), to: 0x10).description
        == "m[0x0000_0000_0000_0010] <- 0x01")
    #expect(
      MMIOTracingInterposerEvent.store(of: UInt16(2), to: 0x10).description
        == "m[0x0000_0000_0000_0010] <- 0x0002")
    #expect(
      MMIOTracingInterposerEvent.store(of: UInt32(3), to: 0x10).description
        == "m[0x0000_0000_0000_0010] <- 0x0000_0003")
    #expect(
      MMIOTracingInterposerEvent.store(of: UInt64(4), to: 0x10).description
        == "m[0x0000_0000_0000_0010] <- 0x0000_0000_0000_0004")
  }
}
