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

protocol XMLNodeInitializable {
  init(_ node: XMLNode) throws
}

extension XMLNodeInitializable
where Self: LosslessStringConvertible {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    self =
      try Self
      .init(stringValue)
      .unwrap(or: Errors.unknownValue(stringValue))
  }
}

extension XMLNodeInitializable
where Self: RawRepresentable, Self.RawValue == String {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    self =
      try Self
      .init(rawValue: stringValue)
      .unwrap(or: Errors.unknownValue(stringValue))
  }
}

extension String: XMLNodeInitializable {
  init(_ node: XMLNode) throws {
    guard let stringValue = node.stringValue else { fatalError() }
    self = stringValue
  }
}

extension Bool: XMLNodeInitializable {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    switch stringValue {
    case "1", "true": self = true
    case "0", "false": self = false
    default: fatalError()
    }
  }
}

// scaledNonNegativeInteger: /^[+]?(0x|0X|#)?[0-9a-fA-F]+[kmgtKMGT]?$/
extension UInt64: XMLNodeInitializable {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    var description = stringValue[...]
    let parser = Parser<Substring, Self>.scaledNonNegativeInteger()
    guard
      let value = parser.run(&description),
      description.isEmpty
    else { throw Errors.unknownValue(stringValue) }

    self = value
  }
}
