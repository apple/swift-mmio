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

struct DecoderFieldsView: View {
  @Binding var base: DecoderDigitInputBase
  var model: DecoderViewModel
  var dynamicModel: DecoderFieldDynamicViewModelBinding

  var body: some View {
    Grid(verticalSpacing: 4) {
      GridRow {
        Text("Name")
        Text("MSB")
        Text("LSB")
        Text("Value")
        Text("Case")
      }
      .font(.subheadline)
      .foregroundStyle(.tertiary)
      .fontWeight(.bold)

      ForEach(self.model.fields) { field in
        DecoderFieldView(
          base: self.$base,
          model: field,
          dynamicModel: self.dynamicModel)
      }
    }
  }
}

#Preview {
  @Previewable @State var base: DecoderDigitInputBase = .octal
  @Previewable var dynamicModel = DecoderFieldDynamicViewModel()

  DecoderFieldDynamicViewModelDebugView(
    dynamicModel: dynamicModel.binding)

  DecoderFieldsView(
    base: $base,
    model: previewModel,
    dynamicModel: dynamicModel.binding)
}
