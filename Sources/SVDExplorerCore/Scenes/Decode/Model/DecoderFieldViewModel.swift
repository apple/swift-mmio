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

struct DecoderFieldViewModel {
  var id: Int
  var name: String
  var bitRange: Range<Int>
  var leastSignificantBit: Int
  var mostSignificantBit: Int

  var caseNames: [String]
  var caseBitPatternToName: [UInt64: String]
  var caseNameToBitPattern: [String: UInt64]
}

extension DecoderFieldViewModel {
  init(id: Int, field: SVDField) {
    self.id = id
    self.name = field.name

    let bitRange = field.bitRange.range
    self.bitRange = Int(bitRange.lowerBound)..<Int(bitRange.upperBound)
    self.leastSignificantBit = Int(bitRange.lowerBound)
    self.mostSignificantBit = Int(bitRange.upperBound) - 1

    self.caseNames = []
    self.caseBitPatternToName = [:]
    self.caseNameToBitPattern = [:]

    for enumeratedValue in field.enumeratedValues?.enumeratedValue ?? [] {
      guard let name = enumeratedValue.name else { continue }
      self.caseNames.append(name)

      switch enumeratedValue.data {
      case .value(let data):
        self.caseNameToBitPattern[name] = data.value.value
        self.caseBitPatternToName[data.value.value] = name
      case .isDefault:
        break
      }
    }
  }
}

extension DecoderFieldViewModel: Decodable {}

extension DecoderFieldViewModel: Encodable {}

extension DecoderFieldViewModel: Equatable {}

extension DecoderFieldViewModel: Hashable {}

extension DecoderFieldViewModel: Identifiable {}
