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

struct DecoderBitUnderlayView: View {
  var lsb: Int
  var msb: Int
  var displayState: DisplayState

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
      // FIXME: This sucks
      ViewThatFits {
        HStack(alignment: .bottom, spacing: 0) {
          Text("\(self.msb)")
            .padding(.leading, 1)
          Spacer(minLength: 4)
          Text("\(self.lsb)")
            .padding(.trailing, 1)
        }

        HStack {
          Text("\(self.msb)")
            .padding(.leading, 1)
          Spacer(minLength: 0)
        }

        Text("")
          .frame(maxWidth: .infinity)
      }
    }
    .lineLimit(1)
    .font(.system(size: 8))
    .foregroundStyle(.secondary)
    .background {
      DecoderPillBackgroundView(
        cornerRadius: 4,
        displayState: self.displayState)
    }
  }
}

#Preview {
  @Previewable @State var lsb: Int = 500
  @Previewable @State var msb: Int = 999
  @Previewable @State var displayState: DisplayState = .default

  HStack {
    Stepper("LSB", value: $lsb, in: 0...1000)
    Stepper("MSB", value: $msb, in: 0...1000)
    Picker("Display State", selection: $displayState) {
      ForEach(DisplayState.allCases) {
        Text("\($0)")
      }
    }
  }

  DecoderBitUnderlayView(
    lsb: lsb,
    msb: msb,
    displayState: displayState)
    .padding(100)
}
