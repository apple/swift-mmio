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

struct DecoderScene: Scene {
  var body: some Scene {
    WindowGroup("Decoder", id: "decoder", for: DecoderViewModel.self) {
      if let model = $0.wrappedValue {
        DecoderView(model: model)
          .edgesIgnoringSafeArea(.top)
          .containerBackground(.ultraThickMaterial, for: .window)
      } else {
        BegoneView()
      }
    }
    .windowStyle(.hiddenTitleBar)
    // FIXME: this seems like a hack
    .defaultSize(width: 10, height: 10)
    // FIXME: this doesn't work
    .windowIdealSize(.fitToContent)
  }
}
