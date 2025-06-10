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

/// The version format is rNpM (N,M = [0 - 99]).
public struct SVDCPURevision {
  public var revision: UInt64
  public var patch: UInt64
}

extension SVDCPURevision: CustomStringConvertible {
  public var description: String { "r\(self.revision)p\(self.patch)" }
}

extension SVDCPURevision: Decodable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let description = try container.decode(String.self)
    guard let instance = Self(description) else {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: container.codingPath,
          debugDescription:
            "Invalid value \"\(description)\" for type \(Self.self)"))
    }
    self = instance
  }
}

extension SVDCPURevision: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.description)
  }
}

extension SVDCPURevision: Equatable {}

extension SVDCPURevision: Hashable {}

extension SVDCPURevision: LosslessStringConvertible {
  public init?(_ description: String) {
    // Some SVD files use a single int value instead of proper revision, parse
    // that into r<>p0
    if let value = UInt64(description) {
      self.revision = value
      self.patch = 0
      return
    }

    guard
      let (revision, patch) = SVDCPURevisionParser().parseAll(description)
    else { return nil }

    self.revision = revision
    self.patch = patch
  }
}

extension SVDCPURevision: Sendable {}

extension SVDCPURevision: XMLElementInitializable {}

private struct SVDCPURevisionParser: ParserProtocol {
  typealias Output = (UInt64, UInt64)

  var parser: some ParserProtocol<Output> = DropParser("r")
    .take(SwiftIntegerParser<UInt64>())
    .skip(DropParser("p"))
    .take(SwiftIntegerParser<UInt64>())

  func parse(_ input: inout Input) -> Output? {
    parser.parse(&input)
  }
}
