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

struct DecoderFieldDynamicViewModel: DynamicProperty {
  @State var value: UInt64 = 0xffffffff
  @State var hover: Int?
  @FocusState var focus: Int?

  var binding: DecoderFieldDynamicViewModelBinding {
    .init(value: self.$value, hover: self.$hover, focus: self.$focus)
  }
}

struct DecoderFieldDynamicViewModelBinding {
  @Binding var value: UInt64
  @Binding var hover: Int?
  @FocusState.Binding var focus: Int?
}

extension DecoderFieldDynamicViewModelBinding {
  func caseName(model: DecoderFieldViewModel) -> String? {
    model.caseBitPatternToName[self.value[bits: model.bitRange]]
  }

  func displayState(model: DecoderFieldViewModel) -> DecoderFieldDisplayState {
    .init(
      focus: model.id == self.focus,
      hover: model.id == self.hover,
      invalid: self.caseName(model: model) == nil)
  }
}

extension DecoderFieldDynamicViewModelBinding {
  func updateValue(
    bits: Range<Int>,
    with keyPress: KeyPress,
    base: DecoderDigitInputBase
  ) -> KeyPress.Result {
    print(keyPress)

    let radix = UInt64(base.radix)
    switch keyPress.key {
    case .upArrow:
      self.value[bits: bits] &+= 1
      return .handled
    case .downArrow:
      self.value[bits: bits] &-= 1
      return .handled
    case .leftArrow:
      let bit: UInt64 = keyPress.modifiers.contains(.option) ? 0b1 : 0b0
      let original = self.value[bits: bits]
      self.value[bits: bits] = (original << 1) | bit
      return .handled
    case .rightArrow:
      let bit: UInt64 = keyPress.modifiers.contains(.option) ? 0b1 : 0b0
      let original = self.value[bits: bits]
      self.value[bits: bits] = (original >> 1) | (bit << (bits.count - 1))
      return .handled
    case .delete, .deleteForward, ._delete:
      self.value[bits: bits] /= radix
      return .handled
    case .clear,
      "k" where keyPress.modifiers.contains(.command):
      self.value[bits: bits] = 0
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
    let parser = Parser.digit(UInt64.self, base: parserBase)
    guard let value = parser.run(&string), string.isEmpty else {
      return .ignored
    }
    let old = self.value[bits: bits]
    let new = old.multipliedReportingOverflow(by: radix)
      .partialValue &+ value
    self.value[bits: bits] = new
    return .handled
  }
}
