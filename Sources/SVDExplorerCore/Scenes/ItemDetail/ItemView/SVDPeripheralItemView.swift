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

import MMIOUtilities
import SVD
import SwiftUI

struct SVDPeripheralItemView: View {
  var peripheral: SVDPeripheral

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ItemHeaderImage(kind: .peripheral)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.peripheral.displayName,
          text: self.peripheral.name)
        Spacer()
        SVDHeaderTitleView(
          alignment: .trailing,
          title: "Base Address",
          text: "\(hex: self.peripheral.baseAddress, bits: 32)")
      }
      ItemDescriptionView(description: self.peripheral.description)
      Grid {
        ItemRegisterPropertiesView(model: self.peripheral.registerProperties)
      }
    }
  }
}
