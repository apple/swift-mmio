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
    return [
      Self.initializableExtension(type: type, members: members),
      Self.structDecodableExtension(type: type, members: members),
    ].compactMap { DeclSyntax(stringLiteral: $0).as(ExtensionDeclSyntax.self) }
  }

  static func initializableExtension(
    type: some TypeSyntaxProtocol, members: [Member]
  ) -> String {
    var `extension` = """
      extension \(type.trimmed): XMLElementInitializable {
        public init(_ element: borrowing XMLElement) throws {

      """
    for member in members {
      switch member.kind {
      case .attribute:
        `extension` += """
              self.\(member.name) = try element.decode(fromAttribute: "\(member.name)")

          """
      case .inline:
        `extension` += """
              self.\(member.name) = try element.decode()

          """
      case .child:
        `extension` += """
              self.\(member.name) = try element.decode(fromChild: "\(member.name)")

          """
      }
    }
    `extension` += """
        }
      }
      """
    return `extension`
  }

  static func structDecodableExtension(
    type: some TypeSyntaxProtocol, members: [Member]
  ) -> String {
    let own = members.filter { $0.kind != .inline }
    let inline = members.filter { $0.kind == .inline }

    var storage = ""
    var slots = ""
    var decodes = ""
    var builds = ""
    for (slot, member) in own.enumerated() {
      let key = member.kind == .attribute ? "@\(member.name)" : member.name
      slots += """
            if field.matches("\(key)") { return \(slot) }

        """
      if member.isArray {
        storage += "  var \(member.name): [\(member.base)] = []\n"
        decodes += """
                case \(slot):
                  self.\(member.name).append(try decoder.decode(\(member.base).self))

          """
      } else {
        storage += "  var \(member.name): \(member.base)? = nil\n"
        decodes += """
                case \(slot):
                  if self.\(member.name) == nil {
                    self.\(member.name) = try decoder.decode(\(member.base).self)
                  }

          """
        if !member.isOptional {
          builds += """
                guard let \(member.name) = self.\(member.name) else { return nil }

            """
        }
      }
    }

    var slotCount = "\(own.count)"
    var inlineSlots = "    var base = \(own.count)\n"
    var inlineDecodes = "      var slot = slot - \(own.count)\n"
    for member in inline {
      let fields = "\(member.base).Fields"
      storage += "  var \(member.name) = \(fields)()\n"
      slotCount += " + \(fields).slotCount"
      inlineSlots += """
            let \(member.name) = \(fields).slot(for: field)
            if \(member.name) >= 0 { return base + \(member.name) }
            base += \(fields).slotCount

        """
      inlineDecodes += """
              if slot < \(fields).slotCount {
                try self.\(member.name).decode(slot: slot, from: &decoder)
                return
              }
              slot -= \(fields).slotCount

        """
      if member.isOptional {
        builds += """
              let \(member.name) = try self.\(member.name).build()

          """
      } else {
        builds += """
              guard let \(member.name) = try self.\(member.name).build() else { return nil }

          """
      }
    }

    let arguments = members.map { member in
      let local =
        member.kind == .inline || !(member.isOptional || member.isArray)
      return "\(member.name): \(local ? "" : "self.")\(member.name)"
    }.joined(separator: ", ")

    return """
      extension \(type.trimmed): XMLStructDecodable {
        public struct Fields: XMLFields {
      \(storage)
          public init() {}

          public static var slotCount: Int { \(slotCount) }

          @inline(__always)
          public static func slot(
            for field: borrowing some CommonFieldDecoder & ~Escapable
          ) -> Int {
      \(slots)\(inline.isEmpty ? "" : inlineSlots)    return -1
          }

          public mutating func decode(
            slot: Int, from decoder: inout some CommonDecoder & ~Escapable
          ) throws(CodingError.Decoding) {
            switch slot {
      \(decodes)      default:
      \(inline.isEmpty ? "" : inlineDecodes)        return
            }
          }

          public consuming func build() throws(CodingError.Decoding) -> \(type.trimmed)? {
      \(builds)    return \(type.trimmed)(\(arguments))
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
