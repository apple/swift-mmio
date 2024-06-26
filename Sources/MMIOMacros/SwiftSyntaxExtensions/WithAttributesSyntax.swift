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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

struct MatchingAttributeAndMacro {
  var attribute: AttributeSyntax
  var macroType: any (ParsableMacro.Type)
}

extension WithAttributesSyntax {
  @discardableResult
  func requireMacro(
    _ macros: [any (ParsableMacro.Type)],
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> (MatchingAttributeAndMacro) {
    precondition(!macros.isEmpty)
    let baseNames = macros.reduce(into: [String: any ParsableMacro.Type]()) {
      $0[$1.baseName] = $1
    }

    var matches = [MatchingAttributeAndMacro]()
    for attribute in self.attributes {
      // Ignore `#if` conditional attributes
      guard case .attribute(let attribute) = attribute else { continue }

      let name = attribute.attributeName
      guard let identifier = name.as(IdentifierTypeSyntax.self) else {
        continue
      }
      if let macroType = baseNames[identifier.name.text] {
        matches.append(.init(attribute: attribute, macroType: macroType))
      }
    }

    switch matches.count {
    case 0:
      throw context.error(
        at: self,
        message: .expectedMemberAnnotatedWithMacro(macros),
        fixIts: macros.map { .insertMacro(node: self, $0) })
    case 1:
      return matches[0]
    default:
      throw context.error(
        at: self,
        message: .expectedMemberAnnotatedWithMacro(macros))
    }
  }
}

extension ErrorDiagnostic {
  static func expectedMemberAnnotatedWithMacro(
    _ macros: [any (ParsableMacro.Type)]
  ) -> Self {
    switch macros.count {
    case 0:
      preconditionFailure("Expected at at least one macro")
    case 1:
      return .init(
        """
        '\(Macro.signature)' type member must be annotated with \
        '\(macros[0].signature)'
        """)
    default:
      guard let last = macros.last else { fatalError() }
      let optionsPrefix =
        macros
        .dropLast()
        .map { "'\($0.signature)'" }
        .joined(separator: ", ")
      let options = "\(optionsPrefix), or '\(last.signature)'"

      return .init(
        """
        '\(Macro.signature)' type member must be annotated with exactly one of \
        \(options)
        """)
    }
  }
}

extension FixIt {
  static func insertMacro(
    node: some WithAttributesSyntax, _ macro: any (ParsableMacro.Type)
  ) -> FixIt {
    // FIXME: https://github.com/swiftlang/swift-syntax/issues/2205
    var newNode = node
    newNode.attributes.append(macro.attributeWithPlaceholders)
    return .replace(
      message: MacroExpansionFixItMessage("Insert '\(macro.signature)' macro"),
      oldNode: node,
      newNode: newNode)
  }
}
