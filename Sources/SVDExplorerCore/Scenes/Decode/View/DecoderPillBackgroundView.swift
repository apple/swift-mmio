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

struct DecoderPillBackgroundView: View {
  var cornerRadius: CGFloat
  var displayState: DecoderFieldDisplayState

  var body: some View {
    RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
      .fill(self.displayState.fill)
      .strokeBorder(self.displayState.strokeBorder, lineWidth: 1)
      .foregroundStyle(self.displayState.foregroundStyle)
  }
}

#Preview {
  @Previewable @State var focus: Bool = false
  @Previewable @State var hover: Bool = false
  @Previewable @State var caseName: DecoderFieldDisplayState.CaseName = .unknown

  Toggle("focus", isOn: $focus)
  Toggle("hover", isOn: $hover)
  Picker("case", selection: $caseName) {
    Text("unknown").tag(DecoderFieldDisplayState.CaseName.unknown)
    Text("invalid").tag(DecoderFieldDisplayState.CaseName.invalid)
    Text("valid").tag(DecoderFieldDisplayState.CaseName.valid("Example"))
  }

  DecoderPillBackgroundView(
    cornerRadius: 40,
    displayState: .init(focus: focus, hover: hover, caseName: caseName))
}
