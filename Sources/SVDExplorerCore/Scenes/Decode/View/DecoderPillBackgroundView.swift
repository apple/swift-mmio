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

//func DecoderPillBackgroundView(
//  cornerRadius: CGFloat,
//  displayState: DecoderFieldDisplayState
//) -> some View {
//  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//    .fill(displayState.fill)
//    .stroke(displayState.stroke, lineWidth: 2)
//}

func DecoderPillBackgroundView(
  cornerRadius: CGFloat,
  displayState: DecoderFieldDisplayState
) -> some View {
  DecoderPillBackgroundView2(cornerRadius: cornerRadius, displayState: displayState)
}

struct DecoderPillBackgroundView2: View {
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
  @Previewable @State var invalid: Bool = false
  
  Toggle("focus", isOn: $focus)
  Toggle("hover", isOn: $hover)
  Toggle("invalid", isOn: $invalid)

  DecoderPillBackgroundView2(
    cornerRadius: 40,
    displayState: .init(focus: focus, hover: hover, invalid: invalid))
}
