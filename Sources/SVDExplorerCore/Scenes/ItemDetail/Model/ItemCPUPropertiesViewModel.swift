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

typealias ItemCPUPropertiesViewModel = SVDCPU

extension ItemCPUPropertiesViewModel {
  private func presentDisplayText(_ value: Bool?) -> String {
    switch value {
    case .some(true): "Present"
    case .some(false): "Not Present"
    case .none: "Unknown"
    }
  }

  var nameDisplayText: String {
    switch self.name {
    case .armCortexM0: "ARM Cortex M0"
    case .armCortexM0p: "ARM Cortex M0P"
    case .armCortexM1: "ARM Cortex M1"
    case .armCortexM3: "ARM Cortex M3"
    case .armCortexM4: "ARM Cortex M4"
    case .armCortexM7: "ARM Cortex M7"
    case .armCortexM23: "ARM Cortex M23"
    case .armCortexM33: "ARM Cortex M33"
    case .armCortexM35P: "ARM Cortex M35P"
    case .armCortexM55: "ARM Cortex M55"
    case .armCortexM85: "ARM Cortex M85"
    case .armSecureCoreSC000: "ARM Secure Core SC000"
    case .armSecureCoreSC300: "ARM Secure Core SC300"
    case .armCortexA5: "ARM Cortex A5"
    case .armCortexA7: "ARM Cortex A7"
    case .armCortexA8: "ARM Cortex A8"
    case .armCortexA9: "ARM Cortex A9"
    case .armCortexA15: "ARM Cortex A15"
    case .armCortexA17: "ARM Cortex A17"
    case .armCortexA53: "ARM Cortex A53"
    case .armCortexA57: "ARM Cortex A57"
    case .armCortexA72: "ARM Cortex A72"
    case .armChinaSTARMC1: "ARM China STAR MC1"
    case .other(let name): name
    }
  }

  var revisionDisplayText: String {
    "\(self.revision.revision)"
  }

  var patchDisplayText: String {
    "\(self.revision.patch)"
  }

  var endiannessDisplayText: String {
    switch self.endian {
    case .little: "Little"
    case .big: "Big"
    case .selectable: "Selectable"
    case .other: "Other"
    }
  }

  var mpuDisplayText: String {
    self.presentDisplayText(self.mpuPresent)
  }

  var fpuDisplayText: String {
    if !self.fpuPresent {
      "None"
    } else if self.fpuDP == true {
      "Double Precision"
    } else {
      "Single Precision"
    }
  }

  var dspPresentDisplayText: String {
    self.presentDisplayText(self.dspPresent)
  }

  var icachePresentDisplayText: String {
    self.presentDisplayText(self.icachePresent)
  }

  var dcachePresentDisplayText: String {
    self.presentDisplayText(self.dcachePresent)
  }

  var itcmPresentDisplayText: String {
    self.presentDisplayText(self.itcmPresent)
  }

  var dtcmPresentDisplayText: String {
    self.presentDisplayText(self.dtcmPresent)
  }

  var vtorPresentDisplayText: String {
    self.presentDisplayText(self.vtorPresent)
  }

  var nvicPrioBitsDisplayText: String {
    "\(self.nvicPrioBits) bits"
  }

  var vendorSystickConfigDisplayText: String {
    if self.vendorSystickConfig {
      "Vendor Specific"
    } else {
      "ARM Defined"
    }
  }

  var deviceNumInterruptsDisplayText: String {
    self.deviceNumInterrupts?.description ?? "Unknown"
  }

  var sauNumRegionsDisplayText: String {
    self.sauNumRegions?.description ?? "Unknown"
  }

  var sauRegionsConfigDisplayText: String {
    if let sauRegionsConfig = self.sauRegionsConfig {
      "\(sauRegionsConfig)"
    } else {
      "Unknown"
    }
  }
}
