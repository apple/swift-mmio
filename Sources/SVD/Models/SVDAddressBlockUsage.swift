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

public import XML

public enum SVDAddressBlockUsage: String {
  case registers
  case buffer
  case reserved
}

extension SVDAddressBlockUsage: Decodable {}

extension SVDAddressBlockUsage: Encodable {}

extension SVDAddressBlockUsage: Equatable {}

extension SVDAddressBlockUsage: Hashable {}

extension SVDAddressBlockUsage: Sendable {}

extension SVDAddressBlockUsage: XMLElementInitializable {
  public init(_ element: borrowing XMLElement) throws {
    let stringValue = try String(element)
    switch stringValue {
    case Self.registers.rawValue: self = .registers
    case Self.buffer.rawValue: self = .buffer
    case Self.reserved.rawValue: self = .reserved
    // FIXME: esp8266.svd
    // FIXME: esp32.svd
    // These SVDs have invalid usage strings
    default: self = .registers
    }
  }
}
