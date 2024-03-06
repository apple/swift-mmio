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

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

public enum SVDCPUName {
  /// Arm Cortex-M0
  case armCortexM0
  /// Arm Cortex-M0+
  case armCortexM0p
  /// Arm Cortex-M1
  case armCortexM1
  /// Arm Cortex-M3
  case armCortexM3
  /// Arm Cortex-M4
  case armCortexM4
  /// Arm Cortex-M7
  case armCortexM7
  /// Arm Cortex-M23
  case armCortexM23
  /// Arm Cortex-M33
  case armCortexM33
  /// Arm Cortex-M35P
  case armCortexM35P
  /// Arm Cortex-M55
  case armCortexM55
  /// Arm Cortex-M85
  case armCortexM85
  /// Arm Secure Core SC000
  case armSecureCoreSC000
  /// Arm Secure Core SC300
  case armSecureCoreSC300
  /// Arm Cortex-A5
  case armCortexA5
  /// Arm Cortex-A7
  case armCortexA7
  /// Arm Cortex-A8
  case armCortexA8
  /// Arm Cortex-A9
  case armCortexA9
  /// Arm Cortex-A15
  case armCortexA15
  /// Arm Cortex-A17
  case armCortexA17
  /// Arm Cortex-A53
  case armCortexA53
  /// Arm Cortex-A57
  case armCortexA57
  /// Arm Cortex-A72
  case armCortexA72
  /// Arm China STAR-MC1
  case armChinaSTARMC1
  /// Other processor architectures
  case other(String)
}

extension SVDCPUName: XMLNodeInitializable {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    switch stringValue {
    case "CM0": self = .armCortexM0
    case "CM0PLUS", "CM0+": self = .armCortexM0p
    case "CM1": self = .armCortexM1
    case "CM3": self = .armCortexM3
    case "CM4": self = .armCortexM4
    case "CM7": self = .armCortexM7
    case "CM23": self = .armCortexM23
    case "CM33": self = .armCortexM33
    case "CM35P": self = .armCortexM35P
    case "CM55": self = .armCortexM55
    case "CM85": self = .armCortexM85
    case "SC000": self = .armSecureCoreSC000
    case "SC300": self = .armSecureCoreSC300
    case "CA5": self = .armCortexA5
    case "CA7": self = .armCortexA7
    case "CA8": self = .armCortexA8
    case "CA9": self = .armCortexA9
    case "CA15": self = .armCortexA15
    case "CA17": self = .armCortexA17
    case "CA53": self = .armCortexA53
    case "CA57": self = .armCortexA57
    case "CA72": self = .armCortexA72
    case "SMC1": self = .armChinaSTARMC1
    default: self = .other(stringValue)
    }
  }
}
