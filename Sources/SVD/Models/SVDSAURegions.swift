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

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

/// Set the configuration for the Secure Attribution Unit (SAU) when they are
/// preconfigured by HW or Firmware.
@XMLElement
public struct SVDSAURegions {
  /// Specify whether the Secure Attribution Units are enabled.
  public var enabled: Bool?
  /// Set the protection mode for disabled regions.
  ///
  /// When the complete SAU is disabled, the whole memory is treated either
  /// "s"=secure or "n"=non-secure. This value is inherited by the `<region>`
  /// element. Refer to element protection for details and predefined values.
  public var protectionWhenDisabled: SVDAccess?
  /// Group to configure SAU regions.
  public var region: [SVDSAURegion]
}

extension SVDSAURegions: Decodable {}

extension SVDSAURegions: Encodable {}

extension SVDSAURegions: Equatable {}

extension SVDSAURegions: Hashable {}

extension SVDSAURegions: Sendable {}
