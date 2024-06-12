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
import SVD

struct SVDFieldItemView: View {
  var field: SVDField

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        SVDHeaderImage(kind: .field)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.field.displayName,
          text: self.field.name)
        Spacer()
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Access",
          text: self.field.accessDisplayName)
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Bit Width",
          text: "\(self.field.bitRange.bitWidth)")
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Bit Range",
          text: "\(self.field.bitRange.lsb):\(self.field.bitRange.msb)")
      }
      if let description = self.field.description {
        SVDItemDescriptionView(title: "Description", text: description)
      }
      if let enumeratedValues = self.field.enumeratedValues, let name = enumeratedValues.name {
        SVDItemDescriptionView(title: "Enumerated Values", text: name)
      }
    }
  }
}
