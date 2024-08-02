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

extension KeyEquivalent {
  // Workaround: rdar://114253438 (Delete key is received as 0x7F and not 0x08)
  static var _delete: Self { "\u{007F}" }
}

extension FixedWidthInteger {
  mutating func update(
    bits: Range<Int>,
    with keyPress: KeyPress,
    base: DecoderBase
  ) -> KeyPress.Result {
    print(keyPress)

    let radix = Self(base.radix)
    switch keyPress.key {
    case .upArrow:
      self[bits: bits] &+= 1
      return .handled
    case .downArrow:
      self[bits: bits] &-= 1
      return .handled
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
    case .delete, .deleteForward, ._delete:
      self[bits: bits] /= radix
      return .handled
    case .clear, 
      "k" where keyPress.modifiers.contains(.command):
      self[bits: bits] = 0
      return .handled
    case .escape:
      print("TODO: handle escape")
      // default focus?
      return .ignored
    case .`return`:
      print("TODO: handle return")
      // next focus?
      return .ignored
    default:
      break
    }

    guard keyPress.characters.count == 1 else { return .ignored }
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
    let old = self[bits: bits]
    let new = old.multipliedReportingOverflow(by: radix)
      .partialValue &+ value
    self[bits: bits] = new
    print("""
      - old: 0x\(String(old, radix: 16))
      - new: 0x\(String(new, radix: 16))
      - saved: 0x\(String(self[bits: bits], radix: 16))
      """)
    return .handled
  }
}
