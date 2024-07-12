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

struct DecoderFieldsView: View {
  @Binding var value: UInt64
  @Binding var base: DecoderBase

  var register: SVDRegister

  var body: some View {
    Grid(verticalSpacing: 4) {
      GridRow {
        Text("Name")
        Spacer()
        Text("Bit Pattern")
        Text("Value")
      }
      .font(.subheadline)
      .foregroundStyle(.tertiary)
      .fontWeight(.bold)

      ForEach(self.register.fields?.field ?? []) { field in
        DecoderFieldView(
          value: self.$value,
          base: self.$base,
          field: field)
      }
    }
  }
}

#Preview {
  @Previewable @State var value: UInt64 = 0
  @Previewable @State var base: DecoderBase = .octal

  DecoderFieldsView(value: $value, base: $base, register: register)
}
