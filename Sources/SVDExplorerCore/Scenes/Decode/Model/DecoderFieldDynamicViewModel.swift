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

import MMIOUtilities
import SwiftUI

struct DecoderFieldDynamicViewModel: DynamicProperty {
  @State var value: UInt64 = 0xffff_ffff
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
  func caseName(
    model: DecoderFieldViewModel
  ) -> DecoderFieldDisplayState.CaseName {
    guard model.caseBitPatternToName.isEmpty else {
      let bitPattern = self.value[bits: model.bitRange]
      return if let caseName = model.caseBitPatternToName[bitPattern] {
        .valid(caseName)
      } else {
        .invalid
      }
    }
    return .unknown
  }

  func displayState(model: DecoderFieldViewModel) -> DecoderFieldDisplayState {
    .init(
      focus: model.id == self.focus,
      hover: model.id == self.hover,
      caseName: self.caseName(model: model))
  }
}

extension DecoderFieldDynamicViewModelBinding {
  func updateValue(
    bits: Range<Int>,
    with keyPress: KeyPress,
    base: DecoderDigitInputBase
  ) -> KeyPress.Result {
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

    let input = keyPress.characters
    guard input.count == 1 else { return .ignored }
    let parser: any ParserProtocol<UInt8> =
      switch base {
      case .octal: BinaryDigitParser()
      case .decimal: OctalDigitParser()
      case .hexadecimal: HexadecimalDigitParser()
      }

    guard let value = parser.parseAll(input) else { return .ignored }
    let old = self.value[bits: bits]
    let new =
      old.multipliedReportingOverflow(by: radix)
      .partialValue &+ UInt64(value)
    self.value[bits: bits] = new
    return .handled
  }
}
