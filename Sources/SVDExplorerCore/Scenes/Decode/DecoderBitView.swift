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
  @State private var selectedRange: [(Int, Int)] = [(1, 1), (2, 4), (18, 18), (23, 29), (59, 60), (62, 63)]

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
    .backgroundPreferenceValue(DecoderBitViewFramePreferenceKey.self) { preferences in
        GeometryReader { geometry in
          ForEach(0..<self.selectedRange.count, id: \.self) { index in
            let (lsb, msb) = self.selectedRange[index]
            let row = lsb.quotientAndRemainder(dividingBy: 32).quotient * 32
            let startAnchor = preferences[.bit(msb)]
            let endAnchor = preferences[.bit(lsb)]
            let rowAnchor = preferences[.labelRow(row)]

            if let startAnchor, let endAnchor, let rowAnchor {
              let startFrame = geometry[startAnchor]
              let endFrame = geometry[endAnchor]

              let minX = startFrame.minX
              let maxX = endFrame.maxX

              let minY = min(endFrame.minY, startFrame.minY)
              let maxY = geometry[rowAnchor].maxY

              let width = maxX - minX
              let height = maxY - minY

              let x = minX + (width / 2)
              let y = minY + (height / 2)

              DecoderBitUnderlayView(
                lsb: lsb,
                msb: msb,
                displayState: self.hovered ? .hovered : .focused)
                .frame(width: width, height: height)
                .position(x: x, y: y)
            }
          }
        }
    }
    .hovered(self.$hovered)
  }

  @State var hovered: Bool = false

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
        .foregroundStyle(upperBitGroup16Active ? .tertiary : .secondary)
      self.emptyCell()
      self.emptyCell()
      Text("\(middleMsb)")
        .padding(.trailing, padding)
        .foregroundStyle(upperBitGroup16Active ? .tertiary : .secondary)
        .gridColumnAlignment(.trailing)
      Text("\(middleLsb)")
        .padding(.leading, padding)
        .foregroundStyle(lowerBitGroup16Active ? .tertiary : .secondary)
      self.emptyCell()
      self.emptyCell()
      Text("\(lsb)")
        .padding(.trailing, padding)
        .foregroundStyle(lowerBitGroup16Active ? .tertiary : .secondary)
        .gridColumnAlignment(.trailing)
        .anchorPreference(
            key: DecoderBitViewFramePreferenceKey.self,
            value: .bounds) { [.labelRow(lsb): $0] }
    }
    .hidden(!self.selectedRange.isEmpty)
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
    .buttonStyle(.bit)
    .anchorPreference(
      key: DecoderBitViewFramePreferenceKey.self,
      value: .bounds) { [.bit(lsb): $0] }
  }

  @ViewBuilder
  func emptyCell() -> some View {
    Spacer().gridCellUnsizedAxes([.vertical, .horizontal])
  }
}

extension ButtonStyle where Self == BitButtonStyle {
  static var bit: BitButtonStyle { .init() }
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
      .foregroundStyle(self.isEnabled ? .primary : .tertiary)
      .frame(width: Self.buttonWidth)
      .contentShape(Rectangle())
  }
}


struct DecoderBitViewFramePreferenceKey: PreferenceKey {
  enum Key: Hashable {
    case bit(Int)
    case labelRow(Int)
  }
  typealias Value = [Key: Anchor<CGRect>]

  static var defaultValue: Value = [:]

  static func reduce(value : inout Value, nextValue: () -> Value) {
    value.merge(nextValue(), uniquingKeysWith: { $1 })
  }
}

#Preview {
  @Previewable @State var value: UInt64 = 0
  var bitWidth = 37
  DecoderBitView(value: $value, bitWidth: bitWidth)
}

