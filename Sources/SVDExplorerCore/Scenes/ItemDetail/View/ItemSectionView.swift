//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

struct ItemSectionView: View {
  @State var isOpen: Bool = true
  var title: String
  var lines: [(String, String)]

  var body: some View {
    GridRow {
      Toggle(isOn: self.$isOpen.animation()) {
        Image(systemName: "chevron.down")
          .rotationEffect(Angle(degrees: self.isOpen ? 0 : -90))
      }
      .toggleStyle(.button)
      .buttonStyle(.plain)
      .gridColumnAlignment(.leading)
      Text(self.title)
        .lineLimit(nil)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(.secondary)
        .fontWeight(.bold)
        .gridColumnAlignment(.trailing)
      Color.clear
        .gridCellUnsizedAxes(.vertical)
        .frame(height: 1)
    }

    if self.isOpen {
      ForEach(self.lines.indices, id: \.self) { index in
        GridRow(alignment: .firstTextBaseline) {
          Spacer()
            .gridCellUnsizedAxes([.vertical, .horizontal])
          Text(self.lines[index].0)
            .multilineTextAlignment(.trailing)
            .lineLimit(nil)
            .foregroundStyle(.secondary)
            .gridColumnAlignment(.trailing)
          Text(self.lines[index].1)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .gridColumnAlignment(.leading)
        }
      }
    }
    Divider()
  }
}
