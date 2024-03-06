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

/// Specifies the bit position of a field within a register by specifying the
/// least significant and the most significant bit position.
@XMLElement
public struct SVDBitRangeLsbMsb {
  public var lsb: UInt64
  public var msb: UInt64
}
