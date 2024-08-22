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

enum XMLElementMacro: ExtensionMacro {
  static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    var `extension` = """
      extension \(type.trimmed): XMLElementInitializable {
        init(_ element: XMLElement) throws {

      """

    for member in declaration.memberBlock.members {
      guard
        let decl = member.decl.as(VariableDeclSyntax.self),
        let binding = decl.bindings.first,
        let name = binding.pattern.as(IdentifierPatternSyntax.self)
      else { continue }
      var xmlAttribute = false
      var xmlInlineElement = false

      for attribute in decl.attributes {
        guard case .attribute(let attribute) = attribute else { continue }
        if attribute.attributeName.description == "XMLAttribute" {
          xmlAttribute = true
        }
        if attribute.attributeName.description == "XMLInlineElement" {
          xmlInlineElement = true
        }
      }

      if xmlAttribute {
        `extension` += """
          self.\(name) = try element.decode(fromAttribute: "\(name)")

          """
      } else if xmlInlineElement {
        `extension` += """
          self.\(name) = try element.decode()

          """
      } else {
        `extension` += """
          self.\(name) = try element.decode(fromChild: "\(name)")

          """
      }
    }

    `extension` += """
        }
      }
      """
    let decl = DeclSyntax(stringLiteral: `extension`)
    return [decl.as(ExtensionDeclSyntax.self)].compactMap { $0 }
  }
}
