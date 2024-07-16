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

struct DecoderFieldView: View {
  @Binding var value: UInt64
  @Binding var base: DecoderBase
  var field: SVDField

  var bitRange: Range<Int>
  var lsb: Int
  var msb: Int

  init(
    value: Binding<UInt64>,
    base: Binding<DecoderBase>,
    field: SVDField
  ) {
    self._value = value
    self._base = base
    self.field = field

    let bitRange = field.bitRange.range
    self.bitRange = Int(bitRange.lowerBound)..<Int(bitRange.upperBound)
    self.lsb = self.bitRange.lowerBound
    self.msb = self.bitRange.upperBound - 1
  }

  var body: some View {
    GridRow(alignment: .firstTextBaseline) {
      Text("\(self.field.name)")
        .font(.system(size: 12, design: .monospaced))
        .gridColumnAlignment(.leading)
      Text("\(self.msb)")
        .font(.system(size: 12, design: .monospaced))
        .gridColumnAlignment(.trailing)
      Text("\(self.lsb)")
        .font(.system(size: 12, design: .monospaced))
        .gridColumnAlignment(.trailing)
      DecoderDigitInputView(
        value: self.$value,
        base: self.$base,
        bitRange: self.bitRange,
        variant: .field)
        .gridColumnAlignment(.trailing)
      DecoderEnumerationInputView(
        value: self.$value,
        field: self.field)
        .gridColumnAlignment(.leading)
    }
  }
}

#Preview {
  @Previewable @State var value: UInt64 = 0xffffffff
  @Previewable @State var base: DecoderBase = .octal

  Grid {
    DecoderFieldView(value: $value, base: $base, field: fields[0])
    DecoderFieldView(value: $value, base: $base, field: fields[1])
    DecoderFieldView(value: $value, base: $base, field: fields[2])
  }
}

extension SVDField: @retroactive Identifiable {
  public var id: String { self.name }
}
