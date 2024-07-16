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

struct DecoderDigitInputView: View {
  @Binding var value: UInt64
  @Binding var base: DecoderBase
  var bitRange: Range<Int>
  var variant: Variant
  @FocusState var focused: Bool
  @State var hovered: Bool = false

  var displayState: DisplayState {
    if self.focused { .focused }
    else if self.hovered { .hovered }
    else { .default }
  }

  var body: some View {
    HStack(alignment: .lastTextBaseline, spacing: 0) {
      if self.variant == .primary {
        Spacer()
      }
      Text("\(String(self.value[bits: self.bitRange], radix: self.base.radix))")
        .font(self.variant.valueFont)
        .multilineTextAlignment(.trailing)
        .lineLimit(1)
        .minimumScaleFactor(0.01)
        .frame(
          minHeight: self.variant == .primary ? 64 : nil,
          alignment: .bottomTrailing)

      Text(self.base.displayText)
        .font(self.variant.baseFont)
        .foregroundStyle(.secondary)
    }
    .padding(self.variant.padding)
    .background {
      DecoderPillBackgroundView(
        cornerRadius: self.variant.cornerRadius,
        displayState: self.displayState)
    }
    .focusable()
    .focused($focused)
    .focusEffectDisabled()
    .hovered($hovered)
    .onKeyPress {
      self.value.update(bits: self.bitRange, with: $0, base: self.base)
    }
  }
}

extension DecoderDigitInputView {
  enum Variant {
    case primary
    case field

    var valueFont: Font {
      switch self {
      case .primary: .system(size: 40, design: .monospaced)
      case .field: .system(size: 12, design: .monospaced)
      }
    }

    var baseFont: Font {
      switch self {
      case .primary: .system(size: 20, design: .monospaced)
      case .field: .system(size: 8, design: .monospaced)
      }
    }

    var cornerRadius: CGFloat {
      switch self {
      case .primary: 8
      case .field: 4
      }
    }

    var padding: CGFloat {
      switch self {
      case .primary: 8
      case .field: 4
      }
    }
  }
}

enum DisplayState {
  case `default`
  case focused
  case hovered
  case unknown
  case invalid

  var fill: Color {
    switch self {
    case .default: .secondary.opacity(0.2)
    case .focused: .blue.opacity(0.3)
    case .hovered: .primary.opacity(0.2)
    case .unknown: .yellow.opacity(0.2)
    case .invalid: .red.opacity(0.2)
    }
  }

  var stroke: Color {
    switch self {
    case .default: .secondary.opacity(0.3)
    case .focused: .blue.opacity(0.4)
    case .hovered: .primary.opacity(0.3)
    case .unknown: .yellow.opacity(0.3)
    case .invalid: .red.opacity(0.3)
    }
  }
}


#Preview {
  @Previewable @State var value: UInt64 = 0
  @Previewable @State var base: DecoderBase = .octal

  DecoderDigitInputView(
    value: $value,
    base: $base,
    bitRange: 0..<32,
    variant: .primary)
    .frame(width: 200, height: 100)

  DecoderDigitInputView(
    value: $value,
    base: $base,
    bitRange: 3..<12,
    variant: .field)
    .frame(width: 200, height: 100)
}
