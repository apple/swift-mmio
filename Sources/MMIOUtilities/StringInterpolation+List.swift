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

extension String.StringInterpolation {
  public mutating func appendInterpolation<C>(
    list collection: C
  ) where C: Collection {
    for (index, element) in collection.enumerated() {
      appendLiteral("'\(element)'")
      if index == collection.count - 2 {
        appendLiteral(", or ")
      } else if index < collection.count - 1 {
        appendLiteral(", ")
      }
    }
  }

  public mutating func appendInterpolation<C>(
    cycle collection: C
  ) where C: Collection {
    for (index, element) in collection.enumerated() {
      appendLiteral("'\(element)'")
      if index < collection.count - 1 {
        appendLiteral(" -> ")
      }
    }
  }
}
