//
//  SVD+Extensions.swift
//  SVDExplorer
//
//  Created by Rauhul Varma on 1/30/24.
//

import SVD

extension SVDBitRange {
  var lsb: UInt64 {
    switch self {
    case .lsbMsb(let lsbMsb):
      lsbMsb.lsb
    case .offsetWidth(let offsetWidth):
      offsetWidth.bitOffset
    case .literal(let literal):
      literal.bitRange.lsb
    }
  }

  var msb: UInt64 {
    switch self {
    case .lsbMsb(let lsbMsb):
      lsbMsb.msb
    case .offsetWidth(let offsetWidth):
      offsetWidth.bitOffset + (offsetWidth.bitWidth ?? 1) - 1
    case .literal(let literal):
      literal.bitRange.msb
    }
  }

  var bitWidth: UInt64 {
    self.msb - self.lsb + 1
  }
}

extension SVDField {
  var accessDisplayName: String {
    switch self.access {
    case .readOnly:
      "Read Only"
    case .writeOnly:
      "Write Only"
    case .readWrite:
      "Read Write"
    case .writeOnce:
      "Write Once"
    case .readWriteOnce:
      "Read Write Once"
    case nil:
      "Unknown"
    }
  }
}
