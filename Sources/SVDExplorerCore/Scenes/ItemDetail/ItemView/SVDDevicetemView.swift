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

struct SVDDeviceItemView: View {
  var device: SVDDevice

  @State var showVendorDetails: Bool = false
  @State var showCPUDetails: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ItemHeaderImage(kind: .device)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.device.displayName,
          text: self.device.name)
      }
      ItemDescriptionView(description: self.device.description)

      Grid {
        ItemSectionView(
          title: "Vendor",
          lines: [
            ("ID", self.device.vendorID ?? "Unknown"),
            ("Series", self.device.series ?? "Unknown"),
            ("Version", self.device.version ?? "Unknown"),
          ])
        ItemRegisterPropertiesView(model: self.device.registerProperties)
        ItemSectionView(
          title: "MCU",
          lines: [
            ("Address Unit Bit Width", "\(self.device.addressUnitBits)"),
            ("Data Bit Width", "\(self.device.width)"),
          ])
        if let cpu = self.device.cpu {
          ItemCPUPropertiesView(model: cpu)
        }
        if let licenseText = self.device.licenseText {
          ItemSectionView(
            title: "License",
            lines: [
              ("Text", licenseText.svdNormalizedText)
            ])
        }
      }
    }
  }
}
