//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension VariableDeclSyntax {
  // Bindings can be `let`s, `var`s, etc...
  func requireBindingSpecifier(
    _ bindingSpecifier: Keyword,
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    guard self.bindingSpecifier.tokenKind == .keyword(bindingSpecifier) else {
      throw context.error(
        at: self.bindingSpecifier,
        message: .expectedBindingSpecifier(bindingSpecifier),
        fixIts: .replaceBindingSpecifier(
          node: self.bindingSpecifier,
          with: bindingSpecifier))
    }
  }
}

extension VariableDeclSyntax {
  // Multiple bindings can occur for variable declarations like:
  // `var a, b: Int`
  var singleBinding: PatternBindingSyntax? {
    guard self.bindings.count == 1 else { return nil }
    return self.bindings.first
  }

  func requireSingleBinding(
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> PatternBindingSyntax {
    guard let binding = self.singleBinding else {
      throw context.error(
        at: self.bindings,
        message: .expectedSingleBinding())
    }
    return binding
  }
}

extension VariableDeclSyntax {
  var isComputedProperty: Bool {
    guard
      self.bindings.count == 1,
      let binding = self.bindings.first
    else {
      // Computed properties cannot have multiple bindings.
      return false
    }

    // Computed properties must have an accessor block
    guard let accessorBlock = binding.accessorBlock else { return false }

    switch accessorBlock.accessors {
    case .accessors(let accessors):
      for accessor in accessors {
        switch accessor.accessorSpecifier.tokenKind {
        case .keyword(.willSet), .keyword(.didSet):
          return false
        default:
          return true
        }
      }
      return false
    case .getter:
      return true
    }
  }
}

extension ErrorDiagnostic {
  static func expectedBindingSpecifier(_ node: Keyword) -> Self {
    .init("'\(Macro.signature)' can only be applied to '\(node)' bindings")
  }

  static func expectedSingleBinding() -> Self {
    .init("'\(Macro.signature)' cannot be applied to compound properties")
  }
}

extension FixIt {
  static func replaceBindingSpecifier(
    node: TokenSyntax,
    with bindingSpecifier: Keyword
  ) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Replace '\(node.trimmed)' with '\(bindingSpecifier)'"),
      oldNode: node,
      newNode: TokenSyntax.keyword(bindingSpecifier))
  }
}
