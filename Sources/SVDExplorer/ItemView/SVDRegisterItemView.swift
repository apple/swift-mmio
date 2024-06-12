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

struct SVDRegisterItemView: View {
  var register: SVDRegister

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        SVDHeaderImage(kind: .register)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.register.displayName,
          text: self.register.name)
        Spacer()
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Bit Width",
          text: "\(self.register.registerProperties.size ?? 0)")
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Address Offset",
          text: "\(self.register.addressOffset)")
      }

      if let description = self.register.description {
        SVDItemDescriptionView(title: "Description", text: description)
      }
    }
  }
}
