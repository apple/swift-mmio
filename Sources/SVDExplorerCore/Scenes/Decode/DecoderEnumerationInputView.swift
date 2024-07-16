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

struct DecoderEnumerationInputView: View {
  @Binding var value: UInt64
  var field: SVDField

  var bitRange: Range<Int>
  var enumeratedValues: [SVDEnumerationCase]
  var names: [String] = []
  var bitPatternToName: [UInt64: String]
  var nameToBitPattern: [String: UInt64]

  @FocusState var focused: Bool
  @State var hovered: Bool = false
  var displayState: DisplayState {
    let value = self.value[bits: self.bitRange]
    let invalid = self.bitPatternToName[value] == nil
    return if self.focused { .focused }
    else if invalid { .invalid }
    else if self.hovered { .hovered }
    else { .default }
  }

  init(
    value: Binding<UInt64>,
    field: SVDField
  ) {
    self._value = value
    self.field = field

    let bitRange = field.bitRange.range
    self.bitRange = Int(bitRange.lowerBound)..<Int(bitRange.upperBound)
    self.enumeratedValues = field.enumeratedValues?.enumeratedValue ?? []
    self.bitPatternToName = [:]
    self.nameToBitPattern = [:]

    for enumeratedValue in field.enumeratedValues?.enumeratedValue ?? [] {
      guard let name = enumeratedValue.name else { continue }
      self.names.append(name)

      switch enumeratedValue.data {
      case .value(let data):
        self.nameToBitPattern[name] = data.value.value
        self.bitPatternToName[data.value.value] = name
      case .isDefault:
        break
      }
    }
  }

  var body: some View {
    Picker("ff", selection: .constant("1")) {
      Text("1").tag("1")
    }
    Menu {
      ForEach(self.names, id: \.self) { name in
        Button {
          let bitPattern = self.nameToBitPattern[name] ?? 0
          self.value[bits: self.bitRange] = bitPattern

        } label: {
          let value = self.value[bits: self.bitRange]
          let current = self.bitPatternToName[value] ?? "Unknown"

//          Image(systemName: "checkmark")
//            .opacity(current == name ? 1 : 0)
//            .font(.system(size: 8, weight: .bold))
          Text(current == name ? "􀆅 \(name)" : "   \(name)")
            .font(.system(size: 12, design: .monospaced))
        }
      }
    } label: {
      let value = self.value[bits: self.bitRange]
      let name = self.bitPatternToName[value] ?? "Unknown"
      Text(name)
        .font(.system(size: 12, design: .monospaced))
        .focused(self.$focused)

    }
    .menuStyle(.borderlessButton)
    .padding(4)
    .hovered(self.$hovered)
    .background {
      DecoderPillBackgroundView(
        cornerRadius: 4,
        displayState: self.displayState)
    }
  }
}

#Preview {
  @Previewable @State var value: UInt64 = 0xffffffff
  DecoderEnumerationInputView(
    value: $value,
    field: fields[1])
  .frame(width: 200, height: 200)
}
