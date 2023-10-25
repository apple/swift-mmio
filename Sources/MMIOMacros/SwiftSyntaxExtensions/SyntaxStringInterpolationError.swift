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
  mutating func appendInterpolation(
    _ node: (some SyntaxProtocol)?,
    trailingTrivia: Trivia = .space
  ) {
    guard let node = node else { return }
    self.appendInterpolation(node)
    self.appendInterpolation(trailingTrivia)
  }

  mutating func appendInterpolation(
    _ nodes: [some SyntaxProtocol],
    intermediateTrivia: Trivia = .newline
  ) {
    guard let first = nodes.first else { return }
    self.appendInterpolation(first)
    for node in nodes.dropFirst() {
      self.appendInterpolation(intermediateTrivia)
      self.appendInterpolation(node)
    }
  }
}
