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

#if canImport(FoundationXML)
import FoundationXML
#endif

public enum SVDBitRange {
  case lsbMsb(SVDBitRangeLsbMsb)
  case offsetWidth(SVDBitRangeOffsetWidth)
  case literal(SVDBitRangeLiteralContainer)
}

extension SVDBitRange: XMLElementInitializable {
  init(_ element: XMLElement) throws {
    if let value = try? SVDBitRangeLsbMsb(element) {
      self = .lsbMsb(value)
    } else if let value = try? SVDBitRangeOffsetWidth(element) {
      self = .offsetWidth(value)
    } else if let value = try? SVDBitRangeLiteralContainer(element) {
      self = .literal(value)
    } else {
      throw Errors.unknownElement(element)
    }
  }
}
