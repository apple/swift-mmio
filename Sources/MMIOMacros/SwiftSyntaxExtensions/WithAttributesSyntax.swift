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

extension WithAttributesSyntax {
  func requireMacro<Macro>(
    _: Macro.Type,
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws where Macro: ParsableMacro {
    for attribute in self.attributes {
      // Ignore `#if` conditional attributes
      guard case .attribute(let attribute) = attribute else { continue }

      let name = attribute.attributeName
      guard let identifier = name.as(IdentifierTypeSyntax.self) else {
        continue
      }
      if identifier.name.text == Macro.baseName { return }
    }

    throw context.error(
      at: self,
      message: .expectedMemberAnnotatedWithMacro(Macro.self),
      fixIts: .insertMacro(node: self, Macro.self))
  }

  func requireMacro(
    _ macros: [any BitFieldMacro.Type],
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> (attribute: AttributeSyntax, type: any BitFieldMacro.Type) {
    let map = macros.reduce(into: [String: any BitFieldMacro.Type]()) {
      $0[$1.baseName] = $1
    }
    var matches = [(AttributeSyntax, any BitFieldMacro.Type)]()
    for attribute in self.attributes {
      // Ignore `#if` conditional attributes
      guard case .attribute(let attribute) = attribute else { continue }

      let name = attribute.attributeName
      guard let identifier = name.as(IdentifierTypeSyntax.self) else {
        continue
      }
      if let value = map[identifier.name.text] {
        matches.append((attribute, value))
      }
    }
    guard matches.count == 1 else {
      throw context.error(
        at: self,
        message: .expectedMemberAnnotatedWithOneOf(macros))
    }
    return matches[0]
  }
}
