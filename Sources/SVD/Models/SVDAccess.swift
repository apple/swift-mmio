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

#if canImport(FoundationXML)
import FoundationXML
#endif

/// Access rights.
public enum SVDAccess {
  /// Read access is permitted. Write operations have an undefined result.
  case readOnly
  /// Read operations have an undefined result. Write access is permitted.
  case writeOnly
  /// Read and write accesses are permitted. Writes affect the state of the
  /// register and reads return the register value.
  case readWrite
  /// Read operations have an undefined results. Only the first write after
  /// reset has an effect.
  case writeOnce
  /// Read access is always permitted. Only the first write access after a
  /// reset will have an effect on the content. Other write operations have
  /// an undefined result.
  case readWriteOnce
}

extension SVDAccess: Decodable {}

extension SVDAccess: Encodable {}

extension SVDAccess: Equatable {}

extension SVDAccess: Hashable {}

extension SVDAccess: Sendable {}

extension SVDAccess: XMLNodeInitializable {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    switch stringValue {
    case "read-only": self = .readOnly
    case "write-only": self = .writeOnly
    case "read-write": self = .readWrite
    case "write-once": self = .writeOnce
    case "read-writeOnce": self = .readWriteOnce
    // FIXME: AT32WB415xx_v2.svd
    case "read-write ": self = .readWrite
    // FIXME: GD32VF103.svd
    case "write": self = .writeOnly
    // FIXME: nrf9160
    case "read-writeonce": self = .readWriteOnce
    default: throw XMLError.unknownValue(stringValue)
    }
  }
}
