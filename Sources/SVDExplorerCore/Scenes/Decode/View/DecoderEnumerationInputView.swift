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
  @Binding var value: UInt64
  var model: DecoderFieldViewModel

  @FocusState var focused: Bool
  @State var hovered: Bool = false
  var displayState: DisplayState {
    let value = self.value[bits: self.model.bitRange]
    let invalid = self.model.caseBitPatternToName[value] == nil
    return if self.focused { .focused }
    else if invalid { .invalid }
    else if self.hovered { .hovered }
    else { .default }
  }

  init(
    value: Binding<UInt64>,
    model: DecoderFieldViewModel
  ) {
    self._value = value
    self.model = model
  }

  var body: some View {
    let selection = Binding<String> {
      let value = self.value[bits: self.model.bitRange]
      let name = self.model.caseBitPatternToName[value] ?? "Unknown"
      return name
    } set: { newValue in
      let bitPattern = self.model.caseNameToBitPattern[newValue] ?? 0
      self.value[bits: self.model.bitRange] = bitPattern
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
        displayState: self.displayState)
    }
    .hovered(self.$hovered)
    .focusable()
    .focusEffectDisabled()
    .focused(self.$focused)
    Spacer()
  }
}

#Preview {
  @Previewable @State var value: UInt64 = 0xffffffff
  DecoderEnumerationInputView(
    value: $value,
    model: previewModel.fields[1])
    .frame(width: 200, height: 200)
}
