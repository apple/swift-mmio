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

struct ItemRegisterPropertiesView: View {
  var model: ItemRegisterPropertiesViewModel

  var body: some View {
    ItemSectionView(
      title: "Register Properties",
      lines: [
        ("Bit Width", self.model.sizeDisplayText),
        ("Access Rights", self.model.accessDisplayText),
        ("Protection", self.model.protectionDisplayText),
        ("Reset Value", self.model.resetValueDisplayText),
        ("Reset Mask", self.model.resetMaskDisplayText),
      ])
  }
}

#Preview {
  let model = ItemRegisterPropertiesViewModel()
  ItemRegisterPropertiesView(model: model)
}
