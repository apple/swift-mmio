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

final class MMIOTracingInterposerEventTests: XCTestCase {
  func test_load() {
    XCTAssertEqual(
      MMIOTracingInterposerEvent.load(of: UInt8(1), from: 0x10),
      MMIOTracingInterposerEvent(load: true, address: 0x10, size: 8, value: 1))
    XCTAssertEqual(
      MMIOTracingInterposerEvent.load(of: UInt16(2), from: 0x10),
      MMIOTracingInterposerEvent(load: true, address: 0x10, size: 16, value: 2))
    XCTAssertEqual(
      MMIOTracingInterposerEvent.load(of: UInt32(3), from: 0x10),
      MMIOTracingInterposerEvent(load: true, address: 0x10, size: 32, value: 3))
    XCTAssertEqual(
      MMIOTracingInterposerEvent.load(of: UInt64(4), from: 0x10),
      MMIOTracingInterposerEvent(load: true, address: 0x10, size: 64, value: 4))
  }

  func test_store() {
    XCTAssertEqual(
      MMIOTracingInterposerEvent.store(of: UInt8(1), to: 0x10),
      MMIOTracingInterposerEvent(load: false, address: 0x10, size: 8, value: 1))
    XCTAssertEqual(
      MMIOTracingInterposerEvent.store(of: UInt16(2), to: 0x10),
      MMIOTracingInterposerEvent(load: false, address: 0x10, size: 16, value: 2))
    XCTAssertEqual(
      MMIOTracingInterposerEvent.store(of: UInt32(3), to: 0x10),
      MMIOTracingInterposerEvent(load: false, address: 0x10, size: 32, value: 3))
    XCTAssertEqual(
      MMIOTracingInterposerEvent.store(of: UInt64(4), to: 0x10),
      MMIOTracingInterposerEvent(load: false, address: 0x10, size: 64, value: 4))
  }

  func test_description() {
    XCTAssertEqual(
      MMIOTracingInterposerEvent.load(of: UInt8(1), from: 0x10).description,
      "m[0x0000_0000_0000_0010] -> 0x01")
    XCTAssertEqual(
      MMIOTracingInterposerEvent.load(of: UInt16(2), from: 0x10).description,
      "m[0x0000_0000_0000_0010] -> 0x0002")
    XCTAssertEqual(
      MMIOTracingInterposerEvent.load(of: UInt32(3), from: 0x10).description,
      "m[0x0000_0000_0000_0010] -> 0x0000_0003")
    XCTAssertEqual(
      MMIOTracingInterposerEvent.load(of: UInt64(4), from: 0x10).description,
      "m[0x0000_0000_0000_0010] -> 0x0000_0000_0000_0004")

    XCTAssertEqual(
      MMIOTracingInterposerEvent.store(of: UInt8(1), to: 0x10).description,
      "m[0x0000_0000_0000_0010] <- 0x01")
    XCTAssertEqual(
      MMIOTracingInterposerEvent.store(of: UInt16(2), to: 0x10).description,
      "m[0x0000_0000_0000_0010] <- 0x0002")
    XCTAssertEqual(
      MMIOTracingInterposerEvent.store(of: UInt32(3), to: 0x10).description,
      "m[0x0000_0000_0000_0010] <- 0x0000_0003")
    XCTAssertEqual(
      MMIOTracingInterposerEvent.store(of: UInt64(4), to: 0x10).description,
      "m[0x0000_0000_0000_0010] <- 0x0000_0000_0000_0004")
  }
}
