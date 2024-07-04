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

struct SVDItemExpandableGridRow: View {
  @Binding var isOn: Bool
  var title: String
  var description: String

  var body: some View {
    GridRow {
      Toggle(isOn: self.$isOn) {
        Image(systemName: self.isOn ? "chevron.down" : "chevron.forward")
      }
      .toggleStyle(.button)
      .buttonStyle(.plain)
      .gridColumnAlignment(.leading)
      Text(self.title)
        .lineLimit(nil)
        .foregroundColor(Color(nsColor: .secondaryLabelColor))
        .gridColumnAlignment(.trailing)
      Text(self.description)
        .lineLimit(nil)
        .foregroundColor(Color(nsColor: .textColor))
        .gridColumnAlignment(.leading)
    }
  }
}

struct SVDItemGridRow: View {
  var title: String
  var description: String

  var body: some View {
    GridRow {
      Spacer()
        .gridCellUnsizedAxes(.horizontal)
      Text(self.title)
        .lineLimit(nil)
        .foregroundColor(Color(nsColor: .secondaryLabelColor))
        .gridColumnAlignment(.trailing)
      Text(self.description)
        .lineLimit(nil)
        .foregroundColor(Color(nsColor: .textColor))
        .gridColumnAlignment(.leading)
    }
  }
}
