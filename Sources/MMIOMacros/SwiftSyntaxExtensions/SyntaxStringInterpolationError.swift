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

import SwiftSyntax
import SwiftSyntaxBuilder

extension SyntaxStringInterpolation {
  mutating func appendInterpolation(_ accessLevel: AccessLevel?) {
    if let accessLevel = accessLevel {
      self.appendInterpolation(raw: accessLevel.rawValue)
      self.appendInterpolation(raw: " ")
    }
  }

  mutating func appendInterpolation<Node: SyntaxProtocol>(
    _ nodes: [Node]
  ) {
    guard let first = nodes.first else { return }
    self.appendInterpolation(first)
    for node in nodes.dropFirst() {
      self.appendInterpolation(.newline)
      self.appendInterpolation(node)
    }
  }
}
