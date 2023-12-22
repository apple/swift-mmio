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

enum SVD2SwiftError: Error {
  case unknownPeripheral(String, [String])
  case derivedFromUnknownPeripheral(String, String, [String])
  case cyclicPeripheralDerivation(ArraySlice<String>)
}

extension SVD2SwiftError: CustomStringConvertible {
  var description: String {
    switch self {
    case .unknownPeripheral(let peripheral, let peripherals):
      "Unknown peripheral '\(peripheral)', valid options: \(list: peripherals)."
    case .derivedFromUnknownPeripheral(
      let peripheral, let derivedFrom, let peripherals):
      """
      Peripheral '\(peripheral)' derived from unknown peripheral \
      '\(derivedFrom)', valid options: \(list: peripherals).
      """
    case .cyclicPeripheralDerivation(let peripherals):
      """
      Peripheral '\(peripherals[0])' has a cyclic dependency on itself, \
      cycle: \(cycle: peripherals).
      """
    }
  }
}
