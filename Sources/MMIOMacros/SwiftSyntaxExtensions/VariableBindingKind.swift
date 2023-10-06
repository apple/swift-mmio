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

enum VariableBindingKind {
  case `var`
  case `let`
  case `inout`
  case unknown(String)
}

extension VariableBindingKind: CustomStringConvertible {
  var description: String {
    switch self {
    case .var:
      "var"
    case .let:
      "let"
    case .inout:
      "inout"
    case .unknown(let string):
      string
    }
  }
}

extension VariableBindingKind: Equatable {}
