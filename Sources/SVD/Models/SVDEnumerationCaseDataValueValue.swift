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
import MMIOUtilities

#if canImport(FoundationXML)
import FoundationXML
#endif

/// literal format: [+]?(((0x|0X)[0-9a-fA-F]+)|([0-9]+)|((#|0b)[01xX]+))
public struct SVDEnumerationCaseDataValueValue {
  public var value: UInt64
  public var mask: UInt64
}

extension SVDEnumerationCaseDataValueValue {
  public func description(bitWidth: Int) -> String {
    guard bitWidth > 0 else { return "" }
    var description = "0b"

    var needle: UInt64 = 1 << (bitWidth - 1)
    while needle > 0 {
      if self.mask & needle == 0 {
        description.append("x")
      } else if self.value & needle > 0 {
        description += "1"
      } else {
        description += "0"
      }
      needle >>= 1
    }

    return description
  }
}

extension SVDEnumerationCaseDataValueValue: Decodable {}

extension SVDEnumerationCaseDataValueValue: Encodable {}

extension SVDEnumerationCaseDataValueValue: Equatable {}

extension SVDEnumerationCaseDataValueValue: Hashable {}

extension SVDEnumerationCaseDataValueValue: Sendable {}

extension SVDEnumerationCaseDataValueValue: XMLNodeInitializable {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    var description = stringValue[...]
    let parser = Parser<Substring, (UInt64, UInt64)>
      .enumeratedValueDataType(UInt64.self)
    guard
      let value = parser.run(&description),
      description.isEmpty
    else { throw XMLError.unknownValue(stringValue) }

    self.value = value.0
    self.mask = value.1
  }
}
