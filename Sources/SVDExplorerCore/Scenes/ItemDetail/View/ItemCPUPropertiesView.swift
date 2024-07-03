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

struct ItemCPUPropertiesView: View {
  var model: ItemCPUPropertiesViewModel

  var body: some View {
    ItemSectionView(
      title: "CPU",
      lines: [
        ("Name", self.model.nameDisplayText),
        ("Revision", self.model.revisionDisplayText),
        ("Patch", self.model.patchDisplayText),
        ("Endianness", self.model.endiannessDisplayText),
        ("MPU", self.model.mpuDisplayText),
        ("FPU", self.model.fpuDisplayText),
        ("SIMD DSP", self.model.dspPresentDisplayText),
        ("Instruction Cache", self.model.icachePresentDisplayText),
        ("Data Cache", self.model.dcachePresentDisplayText),
        (
          "Instruction Tightly Coupled Memory",
          self.model.itcmPresentDisplayText
        ),
        ("Data Tightly Coupled Memory", self.model.dtcmPresentDisplayText),
        ("Vector Table Offset Register", self.model.vtorPresentDisplayText),
        ("NVIC Priority Bits", self.model.nvicPrioBitsDisplayText),
        ("System Tick Config", self.model.vendorSystickConfigDisplayText),
        ("Device Interrupts", self.model.deviceNumInterruptsDisplayText),
        (
          "Secure Attribution Unit Regions", self.model.sauNumRegionsDisplayText
        ),
        (
          "Secure Attribution Unit Config",
          self.model.sauRegionsConfigDisplayText
        ),
      ])
  }
}
