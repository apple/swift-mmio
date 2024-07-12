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
  @Binding var showBinary: Bool
  @Binding var showFields: Bool
  @Binding var base: DecoderBase

  var body: some View {
    HStack {
      Spacer()

      Button {

      } label: {
        Text("0s")
          .foregroundColor(.primary)
      }

      Button {

      } label: {
        Text("1s")
          .foregroundColor(.primary)
      }

      Button {

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
  @Previewable @State var showBinary = true
  @Previewable @State var showFields = true
  @Previewable @State var base: DecoderBase = .hexadecimal
  DecoderControlBarView(
    showBinary: $showBinary,
    showFields: $showFields,
    base: $base)
  .containerBackground(.thickMaterial, for: .window)
}
