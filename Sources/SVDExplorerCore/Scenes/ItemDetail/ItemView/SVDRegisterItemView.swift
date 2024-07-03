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

import SVD
import SwiftUI

struct SVDRegisterItemView: View {
  @Environment(\.openWindow) var openWindow

  var register: SVDRegister

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ItemHeaderImage(kind: .register)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.register.displayName,
          text: self.register.name)
        Spacer()
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Address Offset",
          text: "\(self.register.addressOffset)")
        Button("Decode") {
          self.openWindow(
            id: "decoder",
            value: DecoderViewModel(register: self.register))
        }
      }
      ItemDescriptionView(description: self.register.description)
      Grid {
        ItemRegisterPropertiesView(model: self.register.registerProperties)
        ItemSectionView(
          title: "Register Details",
          lines: [
            ("Data Type", self.register.dataType?.rawValue ?? "Unknown"),
            (
              "Modified Write Values",
              (self.register.modifiedWriteValues ?? .modify).displayText
            ),
            (
              "Write Constraint",
              "\(self.register.writeConstraint?.displayText ?? "No Constraint")"
            ),
            (
              "Read Action",
              self.register.readAction?.rawValue ?? "No Side Effect"
            ),
          ])
      }
    }
  }
}

#Preview {
  SVDRegisterItemView(register: previewRegister)
}
