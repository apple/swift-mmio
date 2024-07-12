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

struct DecoderBitView: View {
  @Binding var value: UInt64
  var bitWidth: Int
  var bitRows: Int

  init(value: Binding<UInt64>, bitWidth: Int) {
    self._value = value
    precondition(bitWidth >= 0 && bitWidth <= 64)
    self.bitWidth = bitWidth
    let rows = bitWidth.quotientAndRemainder(dividingBy: 32)
    self.bitRows = rows.quotient + rows.remainder.signum()
  }

  var body: some View {
    Grid(alignment: .leading, verticalSpacing: 0) {
      ForEach(0..<self.bitRows, id: \.self) { row in
        let row = self.bitRows - row - 1
        GridRow {
          Text("").foregroundStyle(.clear)
        }
        self.bitGroup32(lsb: row * 32)
        self.labelRow(lsb: row * 32)
      }
    }
  }

  @ViewBuilder
  func labelRow(lsb: Int) -> some View {
    let padding: CGFloat = 1
    let middleLsb = lsb + 15
    let middleMsb = lsb + 16
    let msb = lsb + 31
    let upperBitGroup16Active = middleMsb >= self.bitWidth
    let lowerBitGroup16Active = lsb >= self.bitWidth
    GridRow {
      Text("\(msb)")
        .padding(.leading, padding)
        .foregroundStyle(upperBitGroup16Active ? .tertiary : .primary)
      self.emptyCell()
      self.emptyCell()
      Text("\(middleMsb)")
        .padding(.trailing, padding)
        .foregroundStyle(upperBitGroup16Active ? .tertiary : .primary)
        .gridColumnAlignment(.trailing)
      Text("\(middleLsb)")
        .padding(.leading, padding)
        .foregroundStyle(lowerBitGroup16Active ? .tertiary : .primary)
      self.emptyCell()
      self.emptyCell()
      Text("\(lsb)")
        .padding(.trailing, padding)
        .foregroundStyle(lowerBitGroup16Active ? .tertiary : .primary)
        .gridColumnAlignment(.trailing)
    }
    .font(.system(size: 10))
  }

  @ViewBuilder
  func bitGroup32(lsb: Int) -> some View {
    GridRow {
      ForEach(0 ..< 2, id: \.self) { index in
        let index = 2 - index - 1
        self.bitGroup16(lsb: lsb + (index * 16))
      }
    }
  }

  @ViewBuilder
  func bitGroup16(lsb: Int) -> some View {
    ForEach(0 ..< 4, id: \.self) { index in
      let index = 4 - index - 1
      self.bitGroup4(lsb: lsb + (index * 4), last: index == 0)
    }
  }

  @ViewBuilder
  func bitGroup4(lsb: Int, last: Bool) -> some View {
    HStack(spacing: 0) {
      ForEach(0 ..< 4, id: \.self) { index in
        let index = 4 - index - 1
        self.bit(lsb: lsb + index)
      }
      if !last {
        self.emptyCell()
      }
    }
  }

  @ViewBuilder
  func bit(lsb: Int) -> some View {
    let value = self.value[bit: lsb]
    let bitLabel = value ? "1" : "0"
    let disabled = lsb >= self.bitWidth
    Button {
      self.value[bit: lsb].toggle()
    } label: {
      Text(verbatim: bitLabel)
    }
    .disabled(disabled)
    .buttonStyle(BitButtonStyle())
  }

  @ViewBuilder
  func emptyCell() -> some View {
    Spacer().gridCellUnsizedAxes([.vertical, .horizontal])
  }
}

struct BitButtonStyle: ButtonStyle {
  static let buttonWidth: CGFloat = 9
  static let font: Font = .system(size: 12)

  @Environment(\.isEnabled)
  var isEnabled: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .font(Self.font)
      .foregroundStyle(self.isEnabled ? .secondary : .tertiary)
      .frame(width: Self.buttonWidth)
      .contentShape(Rectangle())
  }
}

#Preview {
  @Previewable @State var value: UInt64 = 0
  var bitWidth = 37
  DecoderBitView(value: $value, bitWidth: bitWidth)
}
