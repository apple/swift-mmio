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

struct WelcomeCloseButtonView: View {
  static let defaultColor = Color(.secondaryLabel)
  static let hoveredColor = Color(.tertiaryLabel)

  @Environment(\.dismissWindow) var dismissWindow
  @State var hovered: Bool = false

  var body: some View {
    Button {
      self.dismissWindow()
    } label: {
      Image(systemName: "xmark.circle.fill")
        .foregroundColor(self.hovered ? Self.defaultColor : Self.hoveredColor)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text("Close"))
    .hovered(self.$hovered.animation())
    .padding(10)
    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
  }
}
