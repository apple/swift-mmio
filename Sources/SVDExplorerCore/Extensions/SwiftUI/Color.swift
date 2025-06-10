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

extension Color {
  static var tertiary: Color {
    #if os(macOS)
    return Color(nsColor: NSColor.tertiarySystemFill)
    #else
    return Color(UIColor.tertiarySystemFill)
    #endif
  }
}
