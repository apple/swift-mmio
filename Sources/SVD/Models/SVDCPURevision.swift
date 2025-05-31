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

/// The version format is rNpM (N,M = [0 - 99]).
public struct SVDCPURevision {
  public var revision: UInt64
  public var patch: UInt64
}

extension SVDCPURevision: CustomStringConvertible {
  public var description: String { "r\(self.revision)p\(self.patch)" }
}

extension SVDCPURevision: Decodable {
  public init(from decoder: Decoder) throws {
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
  public func encode(to encoder: Encoder) throws {
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

    enum R: ParsablePrefix {
      static let prefix = "r".utf8[...]
    }

    enum P: ParsablePrefix {
      static let prefix = "p".utf8[...]
    }

    var description = description.utf8[...]
    let parser =
      Parser
      .skip(PrefixParser2<R>.parser())
      .take(SwiftIntegerParser2<UInt64>.parser())
      .skip(PrefixParser2<P>.parser())
      .take(SwiftIntegerParser2<UInt64>.parser())
    guard
      let (revision, patch) = parser.run(&description),
      description.isEmpty
    else { return nil }

    self.revision = revision
    self.patch = patch
  }
}

extension SVDCPURevision: Sendable {}

extension SVDCPURevision: XMLNodeInitializable {}
