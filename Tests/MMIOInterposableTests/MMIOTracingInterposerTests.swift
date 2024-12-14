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

struct MMIOTracingInterposerTests: XCTestCase {
  @Test func memory_load() {
    let interposer = MMIOTracingInterposer()
    interposer.memory[0x10] = 0x5a
    interposer.memory[0x11] = 0xa5
    let value: UInt16 = interposer.load(from: .init(bitPattern: 0x10)!)
    XCTAssertEqual(value, 0xa55a)

    XCTAssertEqual(
      interposer.trace,
      [
        .load(of: UInt16(0xa55a), from: 0x10)
      ])
  }

  @Test func memory_store() {
    let interposer = MMIOTracingInterposer()
    interposer.store(
      UInt16(0xa55a),
      to: .init(bitPattern: 0x10)!)
    XCTAssertEqual(interposer.memory[0x10], 0x5a)
    XCTAssertEqual(interposer.memory[0x11], 0xa5)
    XCTAssertEqual(
      interposer.trace,
      [
        .store(of: UInt16(0xa55a), to: 0x10)
      ])
  }

  @Test func XCTAssertMMIOAlignment_pass() {
    XCTAssertMMIOAlignment(pointer: UnsafePointer<UInt16>(bitPattern: 0x2)!)
  }

  @Test func XCTAssertMMIOAlignment_fail() {
    #if !os(Linux)
    XCTExpectFailure("testing negative case")
    XCTAssertMMIOAlignment(pointer: UnsafePointer<UInt16>(bitPattern: 0x1)!)
    #endif
  }

  @Test func XCTAssertMMIOInterposerTrace_pass() {
    let interposer = MMIOTracingInterposer()
    interposer.trace = [
      .store(of: UInt8(0xa5), to: 0x10),
      .load(of: UInt8(0x5a), from: 0x20),
    ]
    XCTAssertMMIOInterposerTrace(
      interposer: interposer,
      trace: [
        .store(of: UInt8(0xa5), to: 0x10),
        .load(of: UInt8(0x5a), from: 0x20),
      ])
  }

  @Test func XCTAssertMMIOInterposerTrace_fail() {
    #if !os(Linux)
    XCTExpectFailure("testing negative case")
    let interposer = MMIOTracingInterposer()
    interposer.trace = [
      .store(of: UInt8(0xa5), to: 0x10),
      .load(of: UInt8(0x5a), from: 0x20),
    ]
    XCTAssertMMIOInterposerTrace(
      interposer: interposer,
      trace: [
        .load(of: UInt8(0x5a), from: 0x20),
        .load(of: UInt8(0xa6), from: 0x30),
      ])
    #endif
  }
}
