//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

extension KeyEquivalent {
  // Workaround: rdar://114253438 (Delete key is received as 0x7F and not 0x08)
  static var _delete: Self { "\u{007F}" }
}
