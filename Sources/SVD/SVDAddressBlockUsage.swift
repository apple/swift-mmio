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

#if canImport(FoundationXML)
import FoundationXML
#else
import Foundation
#endif

public enum SVDAddressBlockUsage {
  case registers
  case buffer
  case reserved
}

extension SVDAddressBlockUsage: XMLNodeInitializable {
  init(_ node: XMLNode) throws {
    let stringValue = try String(node)
    switch stringValue {
    case "registers": self = .registers
    case "buffer": self = .buffer
    case "reserved": self = .reserved
    // FIXME: esp8266.svd
    // FIXME: esp32.svd
    // These SVDs have invalid usage strings
    default: self = .registers
    }
  }
}
