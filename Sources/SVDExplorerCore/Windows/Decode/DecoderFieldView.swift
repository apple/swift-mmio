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
  var bitRange: Range<UInt64> { self.field.bitRange.range }
  var _bitRange: Range<Int> { Int(self.bitRange.lowerBound)..<Int(self.bitRange.upperBound) }

  var body: some View {
    GridRow {
      Text("\(self.field.name)")
        .gridColumnAlignment(.leading)
      Spacer()
      DecoderDigitInputView(
        value: self.$value,
        base: self.$base,
        bitRange: self._bitRange)
        .gridColumnAlignment(.trailing)
      Text("[\(self.bitRange.lowerBound):\(self.bitRange.upperBound)]")
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
