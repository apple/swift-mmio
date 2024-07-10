//
//  BitEditor.swift
//  
//
//  Created by Rauhul Varma on 7/7/24.
//

import SwiftUI

let bitwiseEditorButtonFont: Font = Font.system(size: 12)
let bitwiseEditorLabelFont: Font = Font.system(size: 10)


struct BitEditor: View {
  var bits: [Bool] = [true, true, true]

  var body: some View {
    Grid(alignment: .leading, verticalSpacing: 0) {
//      let bits = appViewModel.inputExpression.bits

      GridRow {
        ForEach(0 ..< 8, id: \.self) { column in
          HStack(spacing: 0) {
            ForEach((0 + (column * 4)) ..< (4 + (column * 4)), id: \.self) { index in
              bitwiseEditorButton(bits, at: index)
            }
            if column != 7 {
              Spacer()
            }
          }
        }
      }
      .font(bitwiseEditorButtonFont)

      GridRow {
        Text(verbatim: "63")
          .padding(.leading, bitwiseEditorLabelTextPadding)
          .gridCellColumns(4)
        Text(verbatim: "47")
          .gridCellColumns(3)
        Text(verbatim: "32")
          .padding(.trailing, bitwiseEditorLabelTextPadding)
          .gridColumnAlignment(.trailing)
      }
      .font(bitwiseEditorLabelFont)

      GridRow {
        ForEach(8 ..< 16, id: \.self) { column in
          HStack(spacing: 0) {
            ForEach((0 + (column * 4)) ..< (4 + (column * 4)), id: \.self) { index in
              bitwiseEditorButton(bits, at: index)
            }
          }
        }
      }
      .padding(.top, editorVerticalPadding)
      .font(bitwiseEditorButtonFont)

      GridRow {
        Text(verbatim: "31")
          .padding(.leading, bitwiseEditorLabelTextPadding)
          .gridCellColumns(4)
        Text(verbatim: "15")
          .gridCellColumns(3)
        Text(verbatim: "0")
          .padding(.trailing, bitwiseEditorLabelTextPadding)
      }
      .font(bitwiseEditorLabelFont)
    }
    .padding(.bottom)
  }

  @ViewBuilder
  func bitwiseEditorButton(_ bits: [Bool], at index: Int) -> some View {
    let value = true // bits[index]
    let bitLabel = value ? "1" : "0"

    Button {
//      var newBits = appViewModel.inputExpression.bits
//      newBits[index] = !newBits[index]
//      appViewModel.inputExpression.bits = newBits
    } label: {
      Text(verbatim: value ? "1" : "0")
//        .foregroundStyle(.secondary)
    }
    .buttonStyle(BitwiseButtonStyle())
    // (1|0) zero-based index
    .accessibilityLabel(Text(bitLabel))
    .help(Text(bitLabel))
    .accessibilityValue("\(value ? "1" : "0")")
  }

}

let bitwiseEditorLabelTextPadding: CGFloat = 1
let bitwiseEditorButtonWidth: CGFloat = 9
let bitwiseEditorHorizontalSpacing: CGFloat = 12
let editorVerticalPadding: CGFloat = 5.0

struct BitwiseButtonStyle: ButtonStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    ZStack {
      configuration.label
    }
    .frame(width: bitwiseEditorButtonWidth)
    .contentShape(Rectangle())
  }
}

#Preview {
  BitEditor()
}
