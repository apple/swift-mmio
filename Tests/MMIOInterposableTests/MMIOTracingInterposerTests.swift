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

final class MMIOTracingInterposerTests: XCTestCase {
  func test_memory_load() {
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

  func test_memory_store() {
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

  func test_trace_diff() {
    XCTAssertEqual(
      formatTraceDiff(
        expectedTrace: [
          .store(of: UInt8(0xa5), to: 0x10),
          .load(of: UInt8(0x5a), from: 0x20),
        ],
        actualTrace: [
          .load(of: UInt8(0x5a), from: 0x20),
          .load(of: UInt8(0xa6), from: 0x30),
        ]),
      """
      Actual trace (+) differed from expected trace (-):
      -m[0x0000_0000_0000_0010] <- 0xa5
       m[0x0000_0000_0000_0020] -> 0x5a
      +m[0x0000_0000_0000_0030] -> 0xa6
      """)

    XCTAssertEqual(
      formatTraceDiff(
        expectedTrace: [
          .store(of: UInt8(0xa5), to: 0x10),
          .load(of: UInt8(0x5a), from: 0x20),
        ],
        actualTrace: [
          .load(of: UInt8(0x5a), from: 0x20),
          .load(of: UInt8(0xa6), from: 0x30),
        ],
        simple: true),
      """
      Actual trace differed from expected trace:
      Actual:
      m[0x0000_0000_0000_0020] -> 0x5a
      m[0x0000_0000_0000_0030] -> 0xa6

      Expected:
      m[0x0000_0000_0000_0010] <- 0xa5
      m[0x0000_0000_0000_0020] -> 0x5a
      """)
  }

  func test_XCTAssertMMIOAlignment_pass() {
    XCTAssertMMIOAlignment(pointer: UnsafePointer<UInt16>(bitPattern: 0x2)!)
  }

  func test_XCTAssertMMIOAlignment_fail() {
    XCTExpectFailure("testing negative case")
    XCTAssertMMIOAlignment(pointer: UnsafePointer<UInt16>(bitPattern: 0x1)!)
  }

  func test_XCTAssertMMIOInterposerTrace_pass() {
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

  func test_XCTAssertMMIOInterposerTrace_fail() {
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
  }
}
