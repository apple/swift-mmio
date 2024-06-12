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

struct SVDDeviceItemView: View {
  var device: SVDDevice

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        SVDHeaderImage(kind: .device)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.device.displayName,
          text: self.device.name)
      }

      HStack {
        SVDItemDescriptionView(title: "Vendor", text: self.device.vendor ?? "Unknown")
        SVDItemDescriptionView(title: "Vendor ID", text: self.device.vendorID ?? "Unknown")
        SVDItemDescriptionView(title: "Series", text: self.device.series ?? "Unknown")
      }

      if let description = self.device.description {
        SVDItemDescriptionView(title: "Description", text: description)
      }
      if let licenseText = self.device.licenseText {
        SVDItemDescriptionView(title: "License", text: licenseText)
      }
    }
  }
}
