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

struct SVDPeripheralItemView: View {
  var peripheral: SVDPeripheral

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        SVDHeaderImage(kind: .peripheral)
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
      if let description = self.peripheral.description {
        Text(description)
      }
      Divider()
    }
  }
}
