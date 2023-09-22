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

extension VariableDeclSyntax {
  var bindingKind: VariableBindingKind {
    switch self.bindingSpecifier.tokenKind {
    case .keyword(.let):
      return .let
    case .keyword(.inout):
      return .inout
    case .keyword(.var):
      return .var
    default:
      return .unknown(self.bindingSpecifier.text)
    }
  }

  var binding: PatternBindingSyntax? {
    guard self.bindings.count == 1 else { return nil }
    return self.bindings.first
  }
}
