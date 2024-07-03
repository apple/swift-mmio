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

struct DecoderBitUnderlayView: View {
  var model: DecoderFieldViewModel
  var dynamicModel: DecoderFieldDynamicViewModelBinding
  var displayState: DecoderFieldDisplayState {
    self.dynamicModel.displayState(model: self.model)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
      // FIXME: This sucks
      ViewThatFits {
        HStack(alignment: .bottom, spacing: 0) {
          Text("\(self.model.mostSignificantBit)")
            .padding(.leading, 1)
          Spacer(minLength: 4)
          Text("\(self.model.leastSignificantBit)")
            .padding(.trailing, 1)
        }

        HStack {
          Text("\(self.model.mostSignificantBit)")
            .padding(.leading, 1)
          Spacer(minLength: 0)
        }

        Text("")
          .frame(maxWidth: .infinity)
      }
    }
    .lineLimit(1)
    .font(.system(size: 8))
    .foregroundStyle(.secondary)
    .background {
      DecoderPillBackgroundView(
        cornerRadius: 4,
        displayState: self.dynamicModel.displayState(model: self.model))
    }
    .hovered(self.dynamicModel.$hover, equals: self.model.id)
    .onTapGesture { self.dynamicModel.focus = self.model.id }
  }
}

#Preview {
  @Previewable var dynamicModel = DecoderFieldDynamicViewModel()

  DecoderFieldDynamicViewModelDebugView(
    dynamicModel: dynamicModel.binding)

  DecoderBitUnderlayView(
    model: previewModel.fields[0],
    dynamicModel: dynamicModel.binding
  )
  .padding(100)
}
