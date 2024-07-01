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
          text: "\(self.field.bitRange.range.count)")
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Bit Range",
          text: "\(self.range.lowerBound):\(self.range.upperBound)")
      }
      if let description = self.field.description {
        SVDItemDescriptionView(title: "Description", text: description)
      }
      if let access = self.field.access {
        SVDItemDescriptionView(title: "Access", text: "\(access)")
      }
      if let modifiedWriteValues = self.field.modifiedWriteValues {
        SVDItemDescriptionView(title: "Modified Write Values", text: modifiedWriteValues.rawValue)
      }
      if let writeConstraint = self.field.writeConstraint {
        SVDItemDescriptionView(title: "Write Constraint", text: "\(writeConstraint)")
      }
      if let readAction = self.field.readAction {
        SVDItemDescriptionView(title: "Read Action", text: readAction.rawValue)
      }
      if let enumeratedValues = self.field.enumeratedValues, let name = enumeratedValues.name {
        SVDItemDescriptionView(title: "Enumerated Values", text: name)
      }
    }
  }
}
