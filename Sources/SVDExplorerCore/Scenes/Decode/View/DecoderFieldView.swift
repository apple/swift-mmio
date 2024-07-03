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

import SVD
import SwiftUI

struct DecoderFieldView: View {
  @Binding var base: DecoderDigitInputBase
  var model: DecoderFieldViewModel
  var dynamicModel: DecoderFieldDynamicViewModelBinding

  var body: some View {
    GridRow(alignment: .firstTextBaseline) {
      Group {
        Text("\(self.model.name)")
          .gridColumnAlignment(.leading)
        Text("\(self.model.mostSignificantBit)")
          .gridColumnAlignment(.trailing)
        Text("\(self.model.leastSignificantBit)")
          .gridColumnAlignment(.trailing)
      }
      .lineLimit(1)
      .font(.system(size: 12, design: .monospaced))

      DecoderDigitInputView(
        base: self.$base,
        model: self.model,
        dynamicModel: self.dynamicModel,
        variant: .field
      )
      .gridColumnAlignment(.trailing)

      if !self.model.caseBitPatternToName.isEmpty {
        DecoderEnumerationInputView(
          model: self.model,
          dynamicModel: self.dynamicModel
        )
        .gridColumnAlignment(.leading)
      } else {
        Spacer().gridCellUnsizedAxes([.horizontal, .vertical])
      }
    }
  }
}

#Preview {
  @Previewable @State var base: DecoderDigitInputBase = .octal
  @Previewable var dynamicModel = DecoderFieldDynamicViewModel()

  DecoderFieldDynamicViewModelDebugView(
    dynamicModel: dynamicModel.binding)

  Grid {
    DecoderFieldView(
      base: $base,
      model: previewModel.fields[0],
      dynamicModel: dynamicModel.binding)
    DecoderFieldView(
      base: $base,
      model: previewModel.fields[1],
      dynamicModel: dynamicModel.binding)
    DecoderFieldView(
      base: $base,
      model: previewModel.fields[2],
      dynamicModel: dynamicModel.binding)
  }
}
