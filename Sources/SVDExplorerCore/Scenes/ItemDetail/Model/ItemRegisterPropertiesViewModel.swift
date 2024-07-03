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

typealias ItemRegisterPropertiesViewModel = SVDRegisterProperties

extension ItemRegisterPropertiesViewModel {
  var sizeDisplayText: String {
    if let size = self.size {
      "\(size) bits"
    } else {
      "Unknown"
    }
  }

  var accessDisplayText: String {
    self.access?.displayText ?? "Unknown"
  }

  var protectionDisplayText: String {
    if let protection = self.protection {
      switch protection {
      case .secure:
        "Secure"
      case .nonSecure:
        "Non-secure"
      case .privileged:
        "Privileged"
      }
    } else {
      "Unknown"
    }
  }

  var resetValueDisplayText: String {
    if let resetValue = self.resetValue, let size = self.size {
      "\(hex: resetValue, bits: size)"
    } else {
      "Unknown"
    }
  }

  var resetMaskDisplayText: String {
    if let resetMask = self.resetMask, let size = self.size {
      "\(hex: resetMask, bits: size)"
    } else {
      "Unknown"
    }
  }
}
