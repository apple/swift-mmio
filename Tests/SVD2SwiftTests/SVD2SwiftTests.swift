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

final class SVD2SwiftTests: XCTestCase {
  func _do_not_run() {
    Banana.timer1.cr.modify { _, _ in }
  }

  func test() {
    XCTAssertEqual(Banana.timer1.cr.unsafeAddress, 0x40010100)
  }
}
