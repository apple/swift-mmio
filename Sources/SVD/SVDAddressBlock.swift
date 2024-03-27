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

/// Specify an address range uniquely mapped to this peripheral. A peripheral
/// must have at least one address block. If a peripheral is derived form
/// another peripheral, the `<addressBlock>` is not mandatory.
@XMLElement
public struct SVDAddressBlock {
  /// Specifies the start address of an address block relative to the
  /// peripheral baseAddress.
  public var offset: UInt64
  /// Specifies the number of addressUnitBits being covered by this address
  /// block. The end address of an address block results from the sum of
  /// baseAddress, offset, and (size - 1).
  public var size: UInt64
  /// The usage mode of the address block.
  public var usage: SVDAddressBlockUsage
  /// Set the protection level for an address block.
  public var protection: SVDProtection?
}

