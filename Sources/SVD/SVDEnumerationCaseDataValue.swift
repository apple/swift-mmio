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

@XMLElement
public struct SVDEnumerationCaseDataValue {
  public var value: SVDEnumeratedValueDataType
}

extension SVDEnumerationCaseDataValue {
  public func bitPatterns() -> [UInt64] { [] }
}

/// literal format: [+]?(((0x|0X)[0-9a-fA-F]+)|([0-9]+)|((#|0b)[01xX]+))
public struct SVDEnumeratedValueDataType {
  public var value: UInt64
  public var mask: UInt64
}

extension SVDEnumeratedValueDataType: XMLNodeInitializable {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    var description = stringValue[...]
    let parser = Parser<Substring, (UInt64, UInt64)>
      .enumeratedValueDataType(UInt64.self)
    guard
      let value = parser.run(&description),
      description.isEmpty
    else { throw Errors.unknownValue(stringValue) }

    self.value = value.0
    self.mask = value.1
  }
}
