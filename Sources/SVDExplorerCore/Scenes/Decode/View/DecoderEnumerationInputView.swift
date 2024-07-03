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

struct DecoderEnumerationInputView: View {
  var model: DecoderFieldViewModel
  var dynamicModel: DecoderFieldDynamicViewModelBinding

  init(
    model: DecoderFieldViewModel,
    dynamicModel: DecoderFieldDynamicViewModelBinding
  ) {
    self.model = model
    self.dynamicModel = dynamicModel
  }

  var body: some View {
    let selection = Binding<String> {
      let value = self.dynamicModel.value[bits: self.model.bitRange]
      let name = self.model.caseBitPatternToName[value] ?? "Unknown"
      return name
    } set: { newValue in
      let bitPattern = self.model.caseNameToBitPattern[newValue] ?? 0
      self.dynamicModel.value[bits: self.model.bitRange] = bitPattern
    }

    Picker("Value", selection: selection) {
      ForEach(self.model.caseNames, id: \.self) { name in
        Text(name)
          .font(.system(size: 12, design: .monospaced))
          .tag(name)
      }
    } currentValueLabel: {
      Text(selection.wrappedValue)
        .font(.system(size: 12, design: .monospaced))
    }
    .labelsHidden()
    .pickerStyle(.menu)
    .buttonStyle(.borderless)
    .padding(4)
    .background {
      DecoderPillBackgroundView(
        cornerRadius: 4,
        displayState: self.dynamicModel.displayState(model: self.model))
    }
    .hovered(self.dynamicModel.$hover, equals: self.model.id)
    Spacer()
  }
}

#Preview {
  @Previewable var dynamicModel = DecoderFieldDynamicViewModel()
  let binding = dynamicModel.binding

  DecoderFieldDynamicViewModelDebugView(
    dynamicModel: binding)

  DecoderEnumerationInputView(
    model: previewModel.fields[1],
    dynamicModel: binding
  )
  .frame(width: 200, height: 200)
}
