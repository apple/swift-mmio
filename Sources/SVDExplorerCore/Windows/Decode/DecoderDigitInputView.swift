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

enum DisplayState {
  case `default`
  case focused
  case hovered
  case unknown
  case invalid

  var fill: Color {
    switch self {
    case .default: .secondary.opacity(0.2)
    case .focused: .blue.opacity(0.2)
    case .hovered: .secondary.opacity(0.25)
    case .unknown: .yellow.opacity(0.2)
    case .invalid: .red.opacity(0.2)
    }
  }

  var stroke: Color {
    switch self {
    case .default: .secondary.opacity(0.3)
    case .focused: .blue.opacity(0.3)
    case .hovered: .secondary.opacity(0.35)
    case .unknown: .yellow.opacity(0.3)
    case .invalid: .red.opacity(0.3)
    }
  }
}


struct DecoderDigitInputView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.controlSize) var controlSize
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false
  @Binding var value: UInt64
  @Binding var base: DecoderBase
  var bitRange: Range<Int>

  

  var state: DisplayState {
    if self.isFocused { .focused }
    else if self.isHovered { .hovered }
    else { .default }
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 0) {
      Text("\(String(self.value[bits: self.bitRange], radix: self.base.radix))")
        .font(.system(size: 12, design: .monospaced))
        .multilineTextAlignment(.trailing)

      Text(self.base.displayText)
        .font(.system(size: 8, design: .monospaced))
        .foregroundStyle(.secondary)
    }
    .padding(2)
    .background {
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(self.state.fill)
        .stroke(self.state.stroke, lineWidth: 1)
    }
    .focusable()
    .focused($isFocused)
    .focusEffectDisabled()
    .onContinuousHover { phase in
        switch phase {
        case .active: self.isHovered = true
        case .ended: self.isHovered = false
        }
    }
    .onKeyPress {
      // FIXME: Parse hex and delete
      print("KeyPress: \($0)")
      if $0.characters.count == 1, let c = $0.characters.first, let int = UInt64("\(c)") {
        let old = self.value
        let new = old + int
        self.value = new
        // FIXME: FILE BUG
        print("result: handled - \(old) \(new) \(self.value)")
        return .handled
      } else {
        print("result: ignored")
        return .ignored
      }
    }
  }
}

#Preview {
  @Previewable @FocusState var focused: Bool
  @Previewable @State var value: UInt64 = 0
  @Previewable @State var base: DecoderBase = .octal
  var bitRange = 0..<17

  Toggle(
    isOn: .init(
      get: { focused },
      set: { focused = $0 })
  ) {
    Text("Focus")
  }.toggleStyle(.switch)

  DecoderDigitInputView(value: $value, base: $base, bitRange: bitRange)
    .frame(width: 200, height: 100)
    .focused($focused)
}

