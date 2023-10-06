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

extension IntegerLiteralExprSyntax {
  var value: Int? {
    var value = 0
    var literal = self.literal.text[...]

    switch literal.prefix(2) {
    case "0b":
      literal.removeFirst(2)
      while !literal.isEmpty {
        if literal.drop(character: "_") { continue }
        guard let digit = literal.consumeBinaryDigit() else { break }
        value = value * 2 + digit
      }
    case "0o":
      literal.removeFirst(2)
      while !literal.isEmpty {
        if literal.drop(character: "_") { continue }
        guard let digit = literal.consumeOctalDigit() else { break }
        value = value * 8 + digit
      }
    case "0x":
      literal.removeFirst(2)
      while !literal.isEmpty {
        if literal.drop(character: "_") { continue }
        guard let digit = literal.consumeHexadecimalDigit() else { break }
        value = value * 16 + digit
      }
    default:
      while !literal.isEmpty {
        if literal.drop(character: "_") { continue }
        guard let digit = literal.consumeDecimalDigit() else { break }
        value = value * 10 + digit
      }
    }

    guard literal.isEmpty else { return nil }
    return value
  }
}
