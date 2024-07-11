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
  var field: SVDField
  var bitRange: Range<UInt64> { self.field.bitRange.range }
  var _bitRange: Range<Int> { Int(self.bitRange.lowerBound)..<Int(self.bitRange.upperBound) }

  var body: some View {
    GridRow {
      Text("\(self.field.name)")
        .gridColumnAlignment(.leading)
      Spacer()
      HStack(alignment: .lastTextBaseline, spacing: 0) {
        Text("\(String(self.value[bits: self._bitRange], radix: 16))")
          .font(.system(size: 12, design: .monospaced))
        Text("16")
          .font(.system(size: 10, design: .monospaced))
          .foregroundStyle(.secondary)
      }.padding(2)
      .gridColumnAlignment(.trailing)
        .background {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.red.opacity(0.2))
            .stroke(Color.red.opacity(0.3), lineWidth: 1)
        }


      Text("[\(self.bitRange.lowerBound):\(self.bitRange.upperBound)]")
        .gridColumnAlignment(.leading)
    }
  }
}

#Preview {
  @Previewable @State var value: UInt64 = 0xffffffff
  Grid {
    DecoderFieldView(value: $value, field: fields[0])
    DecoderFieldView(value: $value, field: fields[1])
    DecoderFieldView(value: $value, field: fields[2])
  }
}

extension SVDField: @retroactive Identifiable {
  public var id: String { self.name }
}
