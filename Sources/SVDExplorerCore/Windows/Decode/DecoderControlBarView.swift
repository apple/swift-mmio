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
  @Binding var baseSelection: DecoderBase

  var body: some View {
    HStack {
//      Toggle(isOn: self.$showBinary.animation()) {
//        Text(self.showBinary ? "Hide Binary" : "Show Binary")
//      }
//      .toggleStyle(.button)
//      .buttonStyle(.plain)
//
//      Spacer()
//
//      Toggle(isOn: self.$showFields.animation()) {
//        Text(self.showFields ? "Hide Fields" : "Show Fields")
//      }
//      .toggleStyle(.button)
//      .buttonStyle(.plain)
//
      Spacer()

      Button {
        
      } label: {
        Image(systemName: "xmark")
          .foregroundColor(.primary)
      }

      Button {

      } label: {
        Image(systemName: "arrow.clockwise")
          .foregroundColor(.primary)
      }


      Picker("base", selection: self.$baseSelection) {
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
  @Previewable @State var baseSelection: DecoderBase = .hexadecimal
  DecoderControlBarView(
    showBinary: $showBinary,
    showFields: $showFields,
    baseSelection: $baseSelection)
  .containerBackground(.thickMaterial, for: .window)
}
