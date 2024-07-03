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

import MMIOUtilities
import SwiftUI

struct DecoderFieldDynamicViewModelDebugView: View {
  var dynamicModel: DecoderFieldDynamicViewModelBinding

  var body: some View {
    VStack(alignment: .leading) {
      Stepper(
        "Value: \(hex: self.dynamicModel.value)",
        value: self.dynamicModel.$value,
        in: UInt64.min...(UInt64.max >> 2))

      Stepper(
        "Hover: \(self.dynamicModel.hover ?? -1)",
        value: .init(
          get: { self.dynamicModel.hover ?? -1 },
          set: { self.dynamicModel.hover = $0 }),
        in: 0...10)

      Stepper(
        "Focus: \(self.dynamicModel.focus ?? -1)",
        value: .init(
          get: { self.dynamicModel.focus ?? -1 },
          set: { self.dynamicModel.focus = $0 }),
        in: 0...10)
    }
    .fontDesign(.monospaced)
    .background {
      DecoderPillBackgroundView(
        cornerRadius: 4,
        displayState: .init(focus: false, hover: false, caseName: .valid("")))
    }
  }
}

#Preview {
  @Previewable var dynamicModel = DecoderFieldDynamicViewModel()

  DecoderFieldDynamicViewModelDebugView(
    dynamicModel: dynamicModel.binding)
}
