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
import SwiftSyntaxMacros

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

  func require(
    bindingKind: VariableBindingKind,
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    guard self.bindingKind == bindingKind else {
      context.error(
        at: self.bindingSpecifier,
        message: .expectedBindingKind(bindingKind),
        fixIts: .replaceWithVar(node: self.bindingSpecifier)
      )
      throw ExpansionError()
    }
  }
}

extension VariableDeclSyntax {
  var singleBinding: PatternBindingSyntax? {
    guard self.bindings.count == 1 else { return nil }
    return self.bindings.first
  }

  func requireSingleBinding(
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> PatternBindingSyntax {
    guard let binding = self.singleBinding else {
      context.error(
        at: self.bindings,
        message: .expectedSingleBinding())
      throw ExpansionError()
    }
    return binding
  }
}
