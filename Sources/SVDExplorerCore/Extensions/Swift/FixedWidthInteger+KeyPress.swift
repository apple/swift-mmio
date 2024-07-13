//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI
import MMIOUtilities

extension FixedWidthInteger {
  mutating func update(
    bits: Range<Int>,
    with keyPress: KeyPress,
    base: DecoderBase
  ) -> KeyPress.Result {
    print("KeyPress: \(keyPress)")

    let radix = Self(base.radix)
    switch keyPress.key {
    case .leftArrow:
      let bit: Self = keyPress.modifiers.contains(.option) ? 0b1 : 0b0
      let original = self[bits: bits]
      self[bits: bits] = (original << 1) | bit
      return .handled
    case .rightArrow:
      let bit: Self = keyPress.modifiers.contains(.option) ? 0b1 : 0b0
      let original = self[bits: bits]
      self[bits: bits] = (original >> 1) | (bit << (bits.count - 1))
      return .handled
    case .delete, .deleteForward:
      self[bits: bits] /= radix
      return .handled
    case .clear:
      self[bits: bits] = 0
      return .handled
//  case .escape:
//    default focus?
//  case .`return`:
//    next focus?
    default:
      break
    }

    guard keyPress.characters.count == 1 else { return .ignored }
    if keyPress.characters == "\u{7f}" {
      self[bits: bits] /= radix
      return .handled
    }

    let parserBase: IntegerLiteralBase = switch base {
    case .octal: .octal
    case .decimal: .decimal
    case .hexadecimal: .hexadecimal
    }

    var string = keyPress.characters[...]
    let parser = Parser.digit(Self.self, base: parserBase)
    guard let value = parser.run(&string), string.isEmpty else {
      return .ignored
    }
    let original = self[bits: bits]
    self[bits: bits] = original.multipliedReportingOverflow(by: radix)
      .partialValue &+ value
    return .handled
  }
}
