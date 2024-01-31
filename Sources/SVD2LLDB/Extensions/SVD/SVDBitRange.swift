//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SVD

extension SVDBitRange {
  var range: Range<UInt64> {
    switch self {
    case .lsbMsb(let range):
      range.lsb..<range.msb + 1
    case .offsetWidth(let range):
      range.bitOffset..<range.bitOffset + (range.bitWidth ?? 1)
    case .literal(let range):
      range.bitRange.lsb..<range.bitRange.msb + 1
    }
  }
}
