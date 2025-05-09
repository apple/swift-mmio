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

import AppKit
import SwiftUI

extension Image {
  @MainActor
  static var applicationIcon: Image {
    Image(nsImage: NSApp.applicationIconImage)
  }
}
