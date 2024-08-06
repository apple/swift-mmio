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

struct DecoderView: View {
  var model: DecoderViewModel

  @State var value: UInt64 = 0
  @State var showBinary = true
  @State var showFields = true
  @State var showSwift = true
  @State var base: DecoderBase = .hexadecimal

  var body: some View {
    VStack(alignment: .trailing) {

      DecoderControlBarView(
        value: self.$value,
        base: self.$base,
        model: self.model)

      Divider()

      DecoderDigitInputView(
        value: self.$value,
        base: self.$base,
        bitRange: self.model.bitRange,
        variant: .primary)
        .padding(.top, 60)

      Divider()

      DecoderSectionToggleView(
        isOpen: self.$showBinary,
        title: "Binary")

      if self.showBinary {
        DecoderBitView(
          value: self.$value,
          model: self.model)
        Divider()
      }

      DecoderSectionToggleView(
        isOpen: self.$showFields,
        title: "Fields")

      if self.showFields {
        DecoderFieldsView(
          value: self.$value,
          base: self.$base,
          model: self.model)
        Divider()
      }

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
  }
}

#Preview {
  DecoderView(model: previewModel)
}
