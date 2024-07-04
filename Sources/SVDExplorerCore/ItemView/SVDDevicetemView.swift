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

  @State var showVendorDetails: Bool = false
  @State var showCPUDetails: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        SVDHeaderImage(kind: .device)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.device.displayName,
          text: self.device.name)
      }
      if let description = self.device.description {
        Text(description.svdNormalizedText)
      }
      Divider()

      Grid {
        SVDItemExpandableGridRow(isOn: self.$showVendorDetails, title: "Vendor", description: self.device.vendor ?? "Unknown")
        if self.showVendorDetails {
          SVDItemGridRow(title: "ID", description: self.device.vendorID ?? "Unknown")
          SVDItemGridRow(title: "Series", description: self.device.series ?? "Unknown")
          SVDItemGridRow(title: "Version", description: self.device.version ?? "Unknown")
          Divider().gridCellUnsizedAxes(.horizontal)
        }
        SVDItemExpandableGridRow(isOn: self.$showCPUDetails, title: "CPU", description: self.device.cpu.map { "\($0.name)" } ?? "Unknown")
        if let cpu = self.device.cpu, self.showCPUDetails {
          SVDItemGridRow(title: "Revision", description: "\(cpu.revision)")
          SVDItemGridRow(title: "Endianness", description: "\(cpu.endian)")
          SVDItemGridRow(title: "MPU Present", description: "\(cpu.mpuPresent)")
          SVDItemGridRow(title: "FPU Present", description: "\(cpu.fpuPresent)")
          SVDItemGridRow(title: "FPU Double Precision", description: "\(cpu.fpuDP?.description ?? "Unknown")")
          SVDItemGridRow(title: "DSP Present", description: "\(cpu.dspPresent?.description ?? "Unknown")")
          SVDItemGridRow(title: "ICache Present", description: "\(cpu.icachePresent?.description ?? "Unknown")")
          SVDItemGridRow(title: "DCache Present", description: "\(cpu.dcachePresent?.description ?? "Unknown")")
          SVDItemGridRow(title: "ITCM Present", description: "\(cpu.itcmPresent?.description ?? "Unknown")")
          SVDItemGridRow(title: "DTCM Present", description: "\(cpu.dtcmPresent?.description ?? "Unknown")")
          SVDItemGridRow(title: "VTOR Present", description: "\(cpu.vtorPresent?.description ?? "Unknown")")
          SVDItemGridRow(title: "NVIC Priority Bits", description: "\(cpu.nvicPrioBits)")
          SVDItemGridRow(title: "Vendor System Tick Config", description: "\(cpu.vendorSystickConfig)")
          SVDItemGridRow(title: "Device Interrupt Count", description: "\(cpu.deviceNumInterrupts?.description ?? "Unknown")")
          SVDItemGridRow(title: "Security Attribution Unit\nNum Regions", description: "\(cpu.sauNumRegions)")
          SVDItemGridRow(title: "Security Attribution Unit\nRegions Config", description: "\(cpu.sauRegionsConfig)")
          Divider().gridCellUnsizedAxes(.horizontal)
        }
        SVDItemGridRow(title: "Address Unit Bit-width", description: "\(self.device.addressUnitBits)")
        SVDItemGridRow(title: "Data Bit-width", description: "\(self.device.width)")
        SVDItemGridRow(title: "Register Properties", description: "\(self.device.registerProperties)")
        Divider().gridCellUnsizedAxes(.horizontal)
        SVDItemGridRow(title: "License Text", description: self.device.licenseText?.svdNormalizedText ?? "Unknown")
      }
    }
  }
}
