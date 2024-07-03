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
        Text(description)
      }
      HStack {
        Button("Show Vendor Details") { self.showVendorDetails.toggle() }
        Button("Show CPU Details") { self.showCPUDetails.toggle() }
      }
      Divider()

      VStack(alignment: .descriptionTitleAlignment, spacing: 8) {
        SVDItemDescriptionView(title: "Vendor", text: self.device.vendor ?? "Unknown")
        if self.showVendorDetails {
          SVDItemDescriptionView(title: "ID", text: self.device.vendorID ?? "Unknown")
          SVDItemDescriptionView(title: "Series", text: self.device.series ?? "Unknown")
          SVDItemDescriptionView(title: "Version", text: self.device.version ?? "Unknown")
          Divider()
        }
        SVDItemDescriptionView(title: "CPU", text: self.device.cpu.map { "\($0.name)" } ?? "Unknown")
        if self.showCPUDetails, let cpu = self.device.cpu {
          Group {
            SVDItemDescriptionView(title: "Revision", text: "\(cpu.revision)")
            SVDItemDescriptionView(title: "Endianness", text: "\(cpu.endian)")
            SVDItemDescriptionView(title: "MPU Present", text: "\(cpu.mpuPresent)")
            SVDItemDescriptionView(title: "FPU Present", text: "\(cpu.fpuPresent)")
            SVDItemDescriptionView(title: "FPU Double Precision", text: "\(cpu.fpuDP?.description ?? "Unknown")")
            SVDItemDescriptionView(title: "DSP Present", text: "\(cpu.dspPresent?.description ?? "Unknown")")
            SVDItemDescriptionView(title: "ICache Present", text: "\(cpu.icachePresent?.description ?? "Unknown")")
            SVDItemDescriptionView(title: "DCache Present", text: "\(cpu.dcachePresent?.description ?? "Unknown")")
            SVDItemDescriptionView(title: "ITCM Present", text: "\(cpu.itcmPresent?.description ?? "Unknown")")
            SVDItemDescriptionView(title: "DTCM Present", text: "\(cpu.dtcmPresent?.description ?? "Unknown")")
            SVDItemDescriptionView(title: "VTOR Present", text: "\(cpu.vtorPresent?.description ?? "Unknown")")
            SVDItemDescriptionView(title: "NVIC Priority Bits", text: "\(cpu.nvicPrioBits)")
            SVDItemDescriptionView(title: "Vendor System Tick Config", text: "\(cpu.vendorSystickConfig)")
            SVDItemDescriptionView(title: "Device Interrupt Count", text: "\(cpu.deviceNumInterrupts?.description ?? "Unknown")")
//            SVDItemDescriptionView(title: "Security Attribution Unit Num Regions", text: "\(cpu.sauNumRegions)")
//            SVDItemDescriptionView(title: "Security Attribution Unit Regions Config", text: "\(cpu.sauRegionsConfig)")
            Divider()
          }
        }
        SVDItemDescriptionView(title: "Address Unit\nBit-width", text: "\(self.device.addressUnitBits)")
        SVDItemDescriptionView(title: "Data Bit-width", text: "\(self.device.width)")
        SVDItemDescriptionView(title: "Register Properties", text: "\(self.device.registerProperties)")
        Divider()
        SVDItemDescriptionView(title: "License Text", text: self.device.licenseText?.svdNormalizedText ?? "Unknown")
          .font(.system(.body).monospaced())
      }
    }
  }
}
