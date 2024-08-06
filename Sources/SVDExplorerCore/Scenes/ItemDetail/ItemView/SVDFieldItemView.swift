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
  var range: Range<UInt64> { self.field.bitRange.range }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ItemHeaderImage(kind: .field)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.field.displayName,
          text: self.field.name)
        Spacer()
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Access",
          text: self.field.accessDisplayText)
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Bit Width",
          text: "\(self.range.count)")
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Bit Range",
          text: "\(self.range.upperBound - 1):\(self.range.lowerBound)")
      }
      ItemDescriptionView(description: self.field.description)

      Grid {
        ItemSectionView(title: "Field Details", lines: [
          ("Access", "\(self.field.access)"),
          ("Modified Write Values", (self.field.modifiedWriteValues ?? .modify).rawValue),
          ("Write Constraint", "\(self.field.writeConstraint)"),
          ("Read Action", self.field.readAction?.rawValue ?? "Unknown"),
        ])
      }
//      if let enumeratedValues = self.field.enumeratedValues, let name = enumeratedValues.name {
//        SVDItemDescriptionView(title: "Enumerated Values", text: name)
//      }
    }
  }
}
