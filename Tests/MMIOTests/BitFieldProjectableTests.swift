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

final class BitFieldProjectableTests: XCTestCase {
  @Test func bool_fromStorage() {
    XCTAssertEqual(false, Bool(storage: UInt8(0x0)))
    XCTAssertEqual(false, Bool(storage: UInt16(0x0)))
    XCTAssertEqual(false, Bool(storage: UInt32(0x0)))
    #if arch(x86_64) || arch(arm64)
    XCTAssertEqual(false, Bool(storage: UInt64(0x0)))
    #endif

    XCTAssertEqual(true, Bool(storage: UInt8(0x1)))
    XCTAssertEqual(true, Bool(storage: UInt16(0x1)))
    XCTAssertEqual(true, Bool(storage: UInt32(0x1)))
    #if arch(x86_64) || arch(arm64)
    XCTAssertEqual(true, Bool(storage: UInt64(0x1)))
    #endif
  }

  @Test func bool_toStorage() {
    XCTAssertEqual(false.storage(UInt8.self), 0x0)
    XCTAssertEqual(false.storage(UInt16.self), 0x0)
    XCTAssertEqual(false.storage(UInt32.self), 0x0)
    #if arch(x86_64) || arch(arm64)
    XCTAssertEqual(false.storage(UInt64.self), 0x0)
    #endif

    XCTAssertEqual(true.storage(UInt8.self), 0x1)
    XCTAssertEqual(true.storage(UInt16.self), 0x1)
    XCTAssertEqual(true.storage(UInt32.self), 0x1)
    #if arch(x86_64) || arch(arm64)
    XCTAssertEqual(true.storage(UInt64.self), 0x1)
    #endif
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
      XCTAssertEqual(`case`, Example(storage: UInt8(`case`.rawValue)))
      XCTAssertEqual(`case`, Example(storage: UInt16(`case`.rawValue)))
      XCTAssertEqual(`case`, Example(storage: UInt32(`case`.rawValue)))
      #if arch(x86_64) || arch(arm64)
      XCTAssertEqual(`case`, Example(storage: UInt64(`case`.rawValue)))
      #endif
    }
  }

  @Test func rawRepresentable_toStorage() {
    for `case` in Example.allCases {
      XCTAssertEqual(`case`.storage(UInt8.self), UInt8(`case`.rawValue))
      XCTAssertEqual(`case`.storage(UInt16.self), UInt16(`case`.rawValue))
      XCTAssertEqual(`case`.storage(UInt32.self), UInt32(`case`.rawValue))
      #if arch(x86_64) || arch(arm64)
      XCTAssertEqual(`case`.storage(UInt64.self), UInt64(`case`.rawValue))
      #endif
    }
  }
}
