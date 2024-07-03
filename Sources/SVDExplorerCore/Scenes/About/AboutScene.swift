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

import SwiftUI

struct AboutScene: Scene {
  var body: some Scene {
    Window("About SVD Explorer", id: "about") {
      AboutView()
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .containerBackground(.thickMaterial, for: .window)
        .windowMinimizeBehavior(.disabled)
    }
    .windowResizability(.contentSize)
    .restorationBehavior(.disabled)
  }
}
