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

/// Define the regions of the Secure Attribution Unit (SAU). The protection
/// level is inherited from the attribute `<protectionWhenDisabled>` of the
/// enclosing element sauRegionsConfig.
@XMLElement
public struct SVDSAURegion {
  /// Specify whether the Secure Attribution Units are enabled. The following
  /// values can be used: true and false, or 1 and 0. Default value is true.
  @XMLAttribute
  public var enabled: Bool?
  /// Identify the region with a name.
  @XMLAttribute
  public var name: Bool?
  /// Base address of the region.
  public var base: UInt64
  /// Limit address of the region.
  public var limit: UInt64
  /// Value to define the access type of a region.
  public var access: SVDSAUAccess
}
