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

struct DecoderViewModel {
  var name: String
  var bitWidth: Int
  var bitRange: Range<Int>
  var bitRows: Int
  var resetValue: UInt64
  var fields: [DecoderFieldViewModel]
}

extension DecoderViewModel {
  init(register: SVDRegister) {
    self.name = register.name
    self.bitWidth = Int(register.registerProperties.size ?? 0)
    self.bitRange = 0..<self.bitWidth
    let rows = self.bitWidth.quotientAndRemainder(dividingBy: 32)
    self.bitRows = rows.quotient + rows.remainder.signum()
    self.resetValue = register.registerProperties.resetValue ?? 0
    self.fields = (register.fields?.field ?? [])
      .map { DecoderFieldViewModel(id: 0, field: $0) }
      .sorted { $0.mostSignificantBit > $1.mostSignificantBit }
    for index in self.fields.indices {
      self.fields[index].id = index
    }
  }
}

extension DecoderViewModel: Decodable {}

extension DecoderViewModel: Encodable {}

extension DecoderViewModel: Equatable {}

extension DecoderViewModel: Hashable {}

extension DecoderViewModel: Identifiable {
  var id: String { self.name }
}
