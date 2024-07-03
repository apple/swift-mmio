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

      VStack(alignment: .leading, spacing: 8) {
        Text(self.device.description ?? "Unknown")
        Divider()
        HStack {
          SVDItemDescriptionView(title: "Vendor", text: self.device.vendor ?? "Unknown")
          SVDItemDescriptionView(title: "ID", text: self.device.vendorID ?? "Unknown")
        }
        HStack {
          SVDItemDescriptionView(title: "Series", text: self.device.series ?? "Unknown")
          SVDItemDescriptionView(title: "Version", text: self.device.version ?? "Unknown")
        }
        Divider()
        Button("foo") {
          withAnimation {
            self.showCPUDetails.toggle()
          }
        }
        SVDItemDescriptionView(title: "CPU", text: self.device.cpu.map { "\($0.name)" } ?? "Unknown")
        if self.showCPUDetails, let cpu = self.device.cpu {
          Group {
            SVDItemDescriptionView(title: "Revision", text: "\(cpu.revision)")
            SVDItemDescriptionView(title: "Endianness", text: "\(cpu.endian)")
            SVDItemDescriptionView(title: "MPU Present", text: "\(cpu.mpuPresent)")
            SVDItemDescriptionView(title: "FPU Present", text: "\(cpu.fpuPresent)")
            SVDItemDescriptionView(title: "FPU Double Precision", text: "\(cpu.fpuDP)")
            SVDItemDescriptionView(title: "DSP Present", text: "\(cpu.dspPresent)")
            SVDItemDescriptionView(title: "ICache Present", text: "\(cpu.icachePresent)")
            SVDItemDescriptionView(title: "DCache Present", text: "\(cpu.dcachePresent)")
            SVDItemDescriptionView(title: "ITCM Present", text: "\(cpu.itcmPresent)")
            SVDItemDescriptionView(title: "DTCM Present", text: "\(cpu.dtcmPresent)")
            SVDItemDescriptionView(title: "VTOR Present", text: "\(cpu.vtorPresent)")
            SVDItemDescriptionView(title: "NVIC Priority Bits", text: "\(cpu.nvicPrioBits)")
            SVDItemDescriptionView(title: "Vendor Systick Config", text: "\(cpu.vendorSystickConfig)")
            SVDItemDescriptionView(title: "Device Num Interrupts", text: "\(cpu.deviceNumInterrupts)")
            SVDItemDescriptionView(title: "SAU Num Regions", text: "\(cpu.sauNumRegions)")
            SVDItemDescriptionView(title: "SAU Regions Config", text: "\(cpu.sauRegionsConfig)")
            Divider()
          }
          .transition(.opacity.animation(.default))
        }

        SVDItemDescriptionView(title: "Address Unit Bits", text: "\(self.device.addressUnitBits)")
        SVDItemDescriptionView(title: "Width", text: "\(self.device.width)")
        SVDItemDescriptionView(title: "Register Properties", text: "\(self.device.registerProperties)")
        Divider()
        SVDItemDescriptionView(title: "License Text", text: self.device.licenseText ?? "Unknown")
      }
    }
  }
}
