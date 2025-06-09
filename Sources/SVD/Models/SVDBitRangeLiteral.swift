//===----------------------------------------------------------------------===//
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
    guard let (msb, lsb) = SVDBitRangeLiteralParser().parseAll(description)
    else { return nil }
    self.lsb = lsb
    self.msb = msb
  }
}

extension SVDBitRangeLiteral: Sendable {}

extension SVDBitRangeLiteral: XMLElementInitializable {}

private struct SVDBitRangeLiteralParser: ParserProtocol {
  typealias Output = (UInt64, UInt64)

  var parser: some ParserProtocol<Output> = DropParser("[")
    .take(SwiftIntegerParser<UInt64>())
    .skip(DropParser(":"))
    .take(SwiftIntegerParser<UInt64>())
    .skip(DropParser("]"))

  func parse(_ input: inout Input) -> Output? {
    self.parser.parse(&input)
  }
}
