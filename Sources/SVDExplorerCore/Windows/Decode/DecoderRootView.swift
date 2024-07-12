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

struct DecoderRootView: View {
  var register: SVDRegister

  @FocusState var isFocused: Bool

  var bitWidth = 42
  @State var value: UInt64 = 0
  @State var showBinary = true
  @State var showFields = true
  @State var showSwift = true
  @State var base: DecoderBase = .hexadecimal

  var body: some View {
    VStack(alignment: .trailing) {

      DecoderDigitInputView(
        value: self.$value,
        base: self.$base,
        bitRange: 0..<self.bitWidth)
//        variant: .mainInput)

      .frame(maxWidth: .infinity)

      Divider()
//      DecoderControlBarView(
//        showBinary: self.$showBinary,
//        showFields: self.$showFields,
//        base: self.$base)

      Divider()
      DecoderSectionToggleView(
        isOpen: self.$showBinary,
        title: "Binary")

      if self.showBinary {
        DecoderBitView(
          value: self.$value,
          bitWidth: self.bitWidth)
      }

      Divider()
      DecoderSectionToggleView(
        isOpen: self.$showFields,
        title: "Fields")

      if self.showFields {
        DecoderFieldsView(
          value: self.$value,
          base: self.$base,
          register: self.register)
      }

      Divider()
      DecoderSectionToggleView(
        isOpen: self.$showSwift,
        title: "Swift")

      if self.showSwift {
        Text("TODO")
      }

      Spacer()
    }
    .padding(8)
    .clipped()
//    .fixedSize()
//    .onKeyPress { press in
//      value += 1
//      return .handled
//    }
//    .onAppear { self.isFocused = true }
  }
}

#Preview {
  DecoderRootView(register: register)
}


//      HStack(alignment: .lastTextBaseline, spacing: 0) {
//        Text(String(value, radix: self.base.radix))
//          .focused($isFocused)
//          .lineLimit(1)
//          .font(.system(size: 40, design: .monospaced))
//          .minimumScaleFactor(0.01)
//          .frame(height: 132, alignment: .bottomTrailing)
//        Text(self.base.displayText)
//          .font(.system(size: 20, design: .monospaced))
//          .foregroundStyle(.secondary)
//      }
//      .padding(4)
//      .background {
//        RoundedRectangle(cornerRadius: 8, style: .continuous)
//          .fill(Color.red.opacity(0.2))
//          .stroke(Color.red.opacity(0.3), lineWidth: 1)
//      }
//      .focusable()
//      .focusEffectDisabled()
