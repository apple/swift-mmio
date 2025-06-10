//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

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

extension SVDCPUName: CustomStringConvertible {
  public var description: String {
    switch self {
    case .armCortexM0: "CM0"
    case .armCortexM0p: "CM0+"
    case .armCortexM1: "CM1"
    case .armCortexM3: "CM3"
    case .armCortexM4: "CM4"
    case .armCortexM7: "CM7"
    case .armCortexM23: "CM23"
    case .armCortexM33: "CM33"
    case .armCortexM35P: "CM35P"
    case .armCortexM55: "CM55"
    case .armCortexM85: "CM85"
    case .armSecureCoreSC000: "SC000"
    case .armSecureCoreSC300: "SC300"
    case .armCortexA5: "CA5"
    case .armCortexA7: "CA7"
    case .armCortexA8: "CA8"
    case .armCortexA9: "CA9"
    case .armCortexA15: "CA15"
    case .armCortexA17: "CA17"
    case .armCortexA53: "CA53"
    case .armCortexA57: "CA57"
    case .armCortexA72: "CA72"
    case .armChinaSTARMC1: "SMC1"
    case .other(let description): description
    }
  }
}

extension SVDCPUName: Decodable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let description = try container.decode(String.self)
    self = Self(description)
  }
}

extension SVDCPUName: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.description)
  }
}

extension SVDCPUName: Equatable {}

extension SVDCPUName: Hashable {}

extension SVDCPUName: LosslessStringConvertible {
  public init(_ description: String) {
    switch description {
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
    default: self = .other(description)
    }
  }
}

extension SVDCPUName: Sendable {}

extension SVDCPUName: XMLElementInitializable {}
