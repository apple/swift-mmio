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
  @Binding var base: DecoderDigitInputBase
  var model: DecoderFieldViewModel
  var dynamicModel: DecoderFieldDynamicViewModelBinding
  var variant: Variant

  var body: some View {
    HStack(alignment: .lastTextBaseline, spacing: 0) {
      if self.variant == .primary {
        Spacer()
      }
      Text(
        "\(String(self.dynamicModel.value[bits: self.model.bitRange], radix: self.base.radix))"
      )
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
        displayState: self.dynamicModel.displayState(model: self.model))
    }
    .focusable()
    .focused(self.dynamicModel.$focus, equals: self.model.id)
    .focusEffectDisabled()
    .hovered(self.dynamicModel.$hover, equals: self.model.id)
    .onKeyPress {
      self.dynamicModel.updateValue(
        bits: self.model.bitRange,
        with: $0,
        base: self.base)
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

#Preview {
  @Previewable @State var base: DecoderDigitInputBase = .octal
  @Previewable var dynamicModel = DecoderFieldDynamicViewModel()

  DecoderFieldDynamicViewModelDebugView(
    dynamicModel: dynamicModel.binding)

  DecoderDigitInputView(
    base: $base,
    model: previewModel.fields[0],
    dynamicModel: dynamicModel.binding,
    variant: .primary)

  DecoderDigitInputView(
    base: $base,
    model: previewModel.fields[1],
    dynamicModel: dynamicModel.binding,
    variant: .field)

  DecoderDigitInputView(
    base: $base,
    model: previewModel.fields[2],
    dynamicModel: dynamicModel.binding,
    variant: .field)
}
