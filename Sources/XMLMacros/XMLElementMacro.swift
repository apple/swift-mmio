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

enum XMLElementMacro: ExtensionMacro {
  static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    let members = Member.members(of: declaration)
    let source = Self.structDecodableExtension(type: type, members: members)
    return [DeclSyntax(stringLiteral: source).as(ExtensionDeclSyntax.self)]
      .compactMap { $0 }
  }

  static func structDecodableExtension(
    type: some TypeSyntaxProtocol, members: [Member]
  ) -> String {
    let type = type.trimmed
    let own = members.filter { $0.kind != .inline }
    let inline = members.filter { $0.kind == .inline }

    // Each member decodes into storage. Own members take the first slots,
    // then each inline member takes the slots of its type.
    var storage: [String] = []
    var slots: [String] = []
    var decodes: [String] = []
    var builds: [String] = []
    for (slot, member) in own.enumerated() {
      let key = member.kind == .attribute ? "@\(member.name)" : member.name
      slots += [
        "if field.matches(\"\(key)\") {",
        "  return \(slot)",
        "}",
      ]
      decodes.append("case \(slot):")
      if member.isArray {
        storage.append("var \(member.name): [\(member.base)] = []")
        decodes.append(
          "  self.\(member.name).append(try decoder.decode(\(member.base).self))"
        )
      } else {
        storage.append("var \(member.name): \(member.base)? = nil")
        decodes += [
          "  if self.\(member.name) == nil {",
          "    self.\(member.name) = try decoder.decode(\(member.base).self)",
          "  }",
        ]
        if !member.isOptional {
          builds += [
            "guard let \(member.name) = self.\(member.name) else {",
            "  return nil",
            "}",
          ]
        }
      }
    }

    // `base` is the first slot of the next inline member.
    var slotCount = "\(own.count)"
    var base = "\(own.count)"
    var inlineDecodes: [String] = []
    for member in inline {
      let fields = "\(member.base).Fields"
      storage.append("var \(member.name) = \(fields)()")
      slots += [
        "let \(member.name) = \(fields).slot(for: field)",
        "if \(member.name) >= 0 {",
        "  return \(base) + \(member.name)",
        "}",
      ]
      let offset = base.contains(" ") ? "(\(base))" : base
      inlineDecodes += [
        "if slot < \(base) + \(fields).slotCount {",
        "  try self.\(member.name).decode(slot: slot - \(offset), from: &decoder)",
        "  return",
        "}",
      ]
      if member.isOptional {
        builds.append("let \(member.name) = try self.\(member.name).build()")
      } else {
        builds += [
          "guard let \(member.name) = try self.\(member.name).build() else {",
          "  return nil",
          "}",
        ]
      }
      slotCount += " + \(fields).slotCount"
      base = slotCount
    }
    decodes.append("default:")
    decodes += inlineDecodes.map { "  " + $0 }
    decodes.append("  return")

    let arguments = members.map { member in
      let local =
        member.kind == .inline || !(member.isOptional || member.isArray)
      return "\(member.name): \(local ? "" : "self.")\(member.name)"
    }.joined(separator: ", ")

    func indent(_ lines: [String], by count: Int) -> String {
      let prefix = String(repeating: " ", count: count)
      return lines.map { prefix + $0 }.joined(separator: "\n")
    }

    return """
      extension \(type): XMLStructDecodable {
        public struct Fields: XMLFields {
      \(indent(storage, by: 4))

          public init() {
          }

          public static var slotCount: Int {
            \(slotCount)
          }

          @inline(__always)
          public static func slot(
            for field: borrowing some CommonFieldDecoder & ~Escapable
          ) -> Int {
      \(indent(slots, by: 6))
            return -1
          }

          public mutating func decode(
            slot: Int, from decoder: inout some CommonDecoder & ~Escapable
          ) throws(CodingError.Decoding) {
            switch slot {
      \(indent(decodes, by: 6))
            }
          }

          public consuming func build() throws(CodingError.Decoding) -> \(type)? {
      \(indent(builds, by: 6))
            return \(type)(\(arguments))
          }
        }
      }
      """
  }
}

struct Member {
  enum Kind {
    case attribute
    case child
    case inline
  }

  var name: String
  var kind: Kind
  /// The member type without `Optional` and `Array`.
  var base: String
  var isOptional: Bool
  var isArray: Bool

  static func members(of declaration: some DeclGroupSyntax) -> [Member] {
    var members: [Member] = []
    for member in declaration.memberBlock.members {
      guard
        let decl = member.decl.as(VariableDeclSyntax.self),
        let binding = decl.bindings.first,
        let name = binding.pattern.as(IdentifierPatternSyntax.self),
        var type = binding.typeAnnotation?.type
      else { continue }

      var kind = Kind.child
      for attribute in decl.attributes {
        guard case .attribute(let attribute) = attribute else { continue }
        switch attribute.attributeName.trimmedDescription {
        case "XMLAttribute": kind = .attribute
        case "XMLInlineElement": kind = .inline
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
      members.append(
        Member(
          name: name.identifier.text, kind: kind,
          base: type.trimmedDescription, isOptional: isOptional,
          isArray: isArray))
    }
    return members
  }
}
