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

struct DecoderControlBarView: View {
  @Binding var value: UInt64
  @Binding var base: DecoderBase
  var model: DecoderViewModel

  var body: some View {
    HStack {
      Spacer()

      Button {
        self.value = 0
      } label: {
        Text("0s")
          .foregroundColor(.primary)
      }

      Button {
        self.value = .max >> (UInt64.bitWidth - self.model.bitWidth)
      } label: {
        Text("1s")
          .foregroundColor(.primary)
      }

      Button {
        self.value = self.model.resetValue
      } label: {
        Image(systemName: "arrow.clockwise")
          .foregroundColor(.primary)
      }

      Picker("base", selection: self.$base) {
        ForEach(DecoderBase.allCases, id: \.self) {
          Text($0.displayText)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .fixedSize()
    }
  }
}

#Preview {
  @Previewable @State var value: UInt64 = 0
  @Previewable @State var base: DecoderBase = .hexadecimal
  var bitWidth: Int
  var resetValue: UInt64

  DecoderControlBarView(
    value: $value,
    base: $base,
    model: previewModel)
  .containerBackground(.thickMaterial, for: .window)
}
