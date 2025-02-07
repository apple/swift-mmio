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

/// A string in the format `[<msb>:<lsb>]`.
public struct SVDBitRangeLiteral {
  public var lsb: UInt64
  public var msb: UInt64
}

extension SVDBitRangeLiteral: CustomStringConvertible {
  public var description: String { "[\(self.msb):\(self.lsb)]" }
}

// FIXME: encode/decode as single value
extension SVDBitRangeLiteral: Decodable {}

extension SVDBitRangeLiteral: Encodable {}

extension SVDBitRangeLiteral: Equatable {}

extension SVDBitRangeLiteral: Hashable {}

extension SVDBitRangeLiteral: LosslessStringConvertible {
  public init?(_ description: String) {
    var description = description[...]
    let parser =
      Parser
      .skip("[")
      .take(.swiftInteger(UInt64.self))
      .skip(":")
      .take(.swiftInteger(UInt64.self))
      .skip("]")
    guard
      let (msb, lsb) = parser.run(&description),
      description.isEmpty
    else { return nil }

    self.lsb = lsb
    self.msb = msb
  }
}

extension SVDBitRangeLiteral: Sendable {}

extension SVDBitRangeLiteral: XMLNodeInitializable {}
