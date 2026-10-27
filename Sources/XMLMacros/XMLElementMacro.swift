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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Generates a builder that decodes a struct while expat parses its element.
///
/// Each stored property gets a slot in the builder:
/// - A property with `@XMLAttribute` decodes from the attribute with its
///   name.
/// - A property with `@XMLInlineElement` decodes from the same element, with
///   the builder of its type.
/// - Other properties decode from the child elements with their name. An
///   array decodes from all such child elements, other types decode from the
///   first one.
enum XMLElementMacro: ExtensionMacro {
  enum Kind {
    case attribute
    case inlineElement
    case child
  }

  struct Member {
    var name: String
    var kind: Kind
    /// The type without optional and array syntax.
    var baseType: String
    var isOptional: Bool
    var isArray: Bool
  }

  static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    let members = declaration.memberBlock.members.compactMap {
      self.member($0.decl)
    }
    let type = type.trimmed

    var slots = ""
    var attributes = ""
    var children = ""
    var inlineAttributes = ""
    var inlineChildren = ""
    var initializer = ""
    for member in members {
      let name = member.name
      switch member.kind {
      case .attribute:
        slots += "    var \(name) = XMLSlot<\(member.baseType)>()\n"
        attributes += """
                case "\(name)": self.\(name).decode(value)

          """
      case .inlineElement:
        slots += "    var \(name) = \(member.baseType).XMLBuilder()\n"
        inlineAttributes += "      self.\(name).attribute(name, value)\n"
        inlineChildren += """
                if let frame = \(member.baseType).XMLBuilder.child(name, of: builder.member(\\.\(name))) {
                  return frame
                }

          """
      case .child:
        let slot = member.isArray ? "XMLArraySlot" : "XMLSlot"
        slots += "    var \(name) = \(slot)<\(member.baseType)>()\n"
        children += """
                case "\(name)": return builder.decode(\\.\(name))

          """
      }

      let value: String
      switch member.kind {
      case .inlineElement where member.isOptional:
        value = "builder.\(name).buildOptional()"
      case .inlineElement:
        value = "builder.\(name).buildRequired()"
      case _ where member.isArray:
        value = "builder.\(name).get()"
      case _ where member.isOptional:
        value = "builder.\(name).optional()"
      default:
        value = "builder.\(name).required(\"\(name)\")"
      }
      initializer += "    self.\(name) = try \(value)\n"
    }

    let decl: DeclSyntax = """
      extension \(type): XMLElementDecodable {
        public struct XMLBuilder: XMLElementBuilder {
      \(raw: slots)
          public init() {}

          public mutating func attribute(_ name: XMLName, _ value: XMLText) {
            switch name {
      \(raw: attributes)      default: break
            }
      \(raw: inlineAttributes)    }

          public static func child(
            _ name: XMLName,
            of builder: XMLBuilderPointer<Self>
          ) -> XMLFrame? {
            switch name {
      \(raw: children)      default: break
            }
      \(raw: inlineChildren)      return nil
          }

          public mutating func build() throws(XMLBuildError) -> \(type) {
            try \(type)(xmlBuilder: &self)
          }
        }

        init(xmlBuilder builder: inout XMLBuilder) throws(XMLBuildError) {
      \(raw: initializer)  }
      }
      """
    return [decl.as(ExtensionDeclSyntax.self)].compactMap { $0 }
  }

  /// Returns the member for a stored property, or nil for other
  /// declarations.
  static func member(_ decl: DeclSyntax) -> Member? {
    guard
      let decl = decl.as(VariableDeclSyntax.self),
      let binding = decl.bindings.first,
      binding.accessorBlock == nil,
      let name = binding.pattern.as(IdentifierPatternSyntax.self),
      var type = binding.typeAnnotation?.type
    else { return nil }

    var kind = Kind.child
    for attribute in decl.attributes {
      guard case .attribute(let attribute) = attribute else { continue }
      switch attribute.attributeName.trimmedDescription {
      case "XMLAttribute": kind = .attribute
      case "XMLInlineElement": kind = .inlineElement
      default: break
      }
    }

    var isOptional = false
    if let optional = type.as(OptionalTypeSyntax.self) {
      isOptional = true
      type = optional.wrappedType
    }
    var isArray = false
    if let array = type.as(ArrayTypeSyntax.self) {
      isArray = true
      type = array.element
    }

    return Member(
      name: name.identifier.trimmedDescription,
      kind: kind,
      baseType: type.trimmedDescription,
      isOptional: isOptional,
      isArray: isArray)
  }
}
