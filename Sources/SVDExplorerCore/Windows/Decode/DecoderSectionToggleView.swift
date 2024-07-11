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

struct DecoderSectionToggleView: View {
  @Binding var isOpen: Bool
  var title: String

  var body: some View {
    Toggle(isOn: self.$isOpen.animation()) {
      HStack(spacing: 4) {
        Text(self.title.uppercased())
        Image(systemName: self.isOpen ? "chevron.down" : "chevron.forward")
        Spacer()
      }
    }
    .font(.caption2)
    .foregroundStyle(.secondary)
    .toggleStyle(.button)
    .buttonStyle(.plain)
  }
}

#Preview {
  @Previewable @State var isOpen = true
  DecoderSectionToggleView(isOpen: $isOpen, title: "Section")
}
