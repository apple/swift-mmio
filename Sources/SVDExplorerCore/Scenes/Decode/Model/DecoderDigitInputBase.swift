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

enum DecoderDigitInputBase: CaseIterable {
  case octal
  case decimal
  case hexadecimal
}

extension DecoderDigitInputBase {
  var displayText: String {
    switch self {
    case .octal: "8"
    case .decimal: "10"
    case .hexadecimal: "16"
    }
  }

  var radix: Int {
    switch self {
    case .octal: 8
    case .decimal: 10
    case .hexadecimal: 16
    }
  }
}
