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

/// Specifies the bit position of a field within a register by specifying the
/// least significant bit position and the bitWidth of the field.
@XMLElement
public struct SVDBitRangeOffsetWidth {
  public var bitOffset: UInt64
  public var bitWidth: UInt64?
}
