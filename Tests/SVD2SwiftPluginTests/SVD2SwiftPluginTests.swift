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

struct SVD2SwiftPluginTests {
  func neverActuallyRun() {
    Banana.timer1.cr.modify { _, _ in }
  }

  @Test func validateAddress() {
    #expect(Banana.timer1.cr.unsafeAddress == 0x4001_0100)
  }
}
