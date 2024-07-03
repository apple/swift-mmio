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
        GridRow {
          Toggle(isOn: self.$showVendorDetails) {
            Image(systemName: self.showVendorDetails ? "chevron.down" : "chevron.forward")
          }
          .toggleStyle(.button)
          .buttonStyle(.plain)
          Text("Vendor")
            .foregroundColor(Color(nsColor: .secondaryLabelColor))
            .gridColumnAlignment(.trailing)
          Text(self.device.vendor ?? "Unknown")
            .foregroundColor(Color(nsColor: .textColor))
            .gridColumnAlignment(.leading)
        }


        if self.showVendorDetails {
          foo("ID", value: self.device.vendorID ?? "Unknown")
          foo("Series", value: self.device.series ?? "Unknown")
          foo("Version", value: self.device.version ?? "Unknown")
          Divider()
        }
        foo("CPU", value: self.device.cpu.map { "\($0.name)" } ?? "Unknown")
        if let cpu = self.device.cpu, self.showCPUDetails {
          Group {
              foo("Revision", value: "\(cpu.revision)")
              foo("Endianness", value: "\(cpu.endian)")
              foo("MPU Present", value: "\(cpu.mpuPresent)")
              foo("FPU Present", value: "\(cpu.fpuPresent)")
              foo("FPU Double Precision", value: "\(cpu.fpuDP?.description ?? "Unknown")")
              foo("DSP Present", value: "\(cpu.dspPresent?.description ?? "Unknown")")
              foo("ICache Present", value: "\(cpu.icachePresent?.description ?? "Unknown")")
              foo("DCache Present", value: "\(cpu.dcachePresent?.description ?? "Unknown")")
              foo("ITCM Present", value: "\(cpu.itcmPresent?.description ?? "Unknown")")
              foo("DTCM Present", value: "\(cpu.dtcmPresent?.description ?? "Unknown")")
              foo("VTOR Present", value: "\(cpu.vtorPresent?.description ?? "Unknown")")
              foo("NVIC Priority Bits", value: "\(cpu.nvicPrioBits)")
              foo("Vendor System Tick Config", value: "\(cpu.vendorSystickConfig)")
              foo("Device Interrupt Count", value: "\(cpu.deviceNumInterrupts?.description ?? "Unknown")")
              foo("Security Attribution Unit Num Regions", value: "\(cpu.sauNumRegions)")
              foo("Security Attribution Unit Regions Config", value: "\(cpu.sauRegionsConfig)")
              Divider()
          }
        }
        foo("Address Unit Bit-width", value: "\(self.device.addressUnitBits)")
        foo("Data Bit-width", value: "\(self.device.width)")
        foo("Register Properties", value: "\(self.device.registerProperties)")
        Divider()
        foo("License Text", value: self.device.licenseText?.svdNormalizedText ?? "Unknown")
          .font(.system(.body).monospaced())
      }


    }
  }
}

func foo(_ title: String, value: String) -> some View {
  GridRow {
    Image(systemName: "chevron.down")
      .toggleStyle(.button)
      .buttonStyle(.plain)
      .opacity(0)
    Text(title)
      .foregroundColor(Color(nsColor: .secondaryLabelColor))
      .gridColumnAlignment(.trailing)
    Text(value)
      .foregroundColor(Color(nsColor: .textColor))
      .gridColumnAlignment(.leading)
  }
}

struct MyGridRow {

}
