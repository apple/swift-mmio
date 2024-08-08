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
import SVD

struct DecoderFieldView: View {
  @Binding var base: DecoderDigitInputBase
  var model: DecoderFieldViewModel
  var dynamicModel: DecoderFieldDynamicViewModelBinding

  var body: some View {
    GridRow(alignment: .firstTextBaseline) {
      Text("\(self.model.name)")
        .font(.system(size: 12, design: .monospaced))
        .gridColumnAlignment(.leading)
      Text("\(self.model.mostSignificantBit)")
        .font(.system(size: 12, design: .monospaced))
        .gridColumnAlignment(.trailing)
      Text("\(self.model.leastSignificantBit)")
        .font(.system(size: 12, design: .monospaced))
        .gridColumnAlignment(.trailing)
      DecoderDigitInputView(
        base: self.$base,
        model: self.model,
        dynamicModel: self.dynamicModel,
        variant: .field)
        .gridColumnAlignment(.trailing)
      DecoderEnumerationInputView(
        model: self.model,
        dynamicModel: self.dynamicModel)
        .gridColumnAlignment(.leading)
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
