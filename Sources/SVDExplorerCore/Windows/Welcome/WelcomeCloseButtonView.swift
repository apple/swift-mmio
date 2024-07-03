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
  static let defaultColor = Color(.secondaryLabelColor)
  static let hoveringColor = Color(.tertiaryLabelColor)

  @Environment(\.dismissWindow) var dismissWindow
  @State var isHovering: Bool = false

  var body: some View {
    Button {
      self.dismissWindow()
    } label: {
      Image(systemName: "xmark.circle.fill")
        .foregroundColor(self.isHovering ? Self.defaultColor : Self.hoveringColor)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text("Close"))
    .onHover { hover in
      withAnimation(.default) {
        self.isHovering = hover
      }
    }
    .padding(10)
    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
  }
}
