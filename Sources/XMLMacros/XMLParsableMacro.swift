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

enum XMLParsableMacro: ExtensionMacro {
  static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    var members = [(IdentifierPatternSyntax, TypeSyntax)]()
    for member in declaration.memberBlock.members {
      guard
        let decl = member.decl.as(VariableDeclSyntax.self),
        let binding = decl.bindings.first,
        let name = binding.pattern.as(IdentifierPatternSyntax.self),
        let type = binding.typeAnnotation?.type
      else { continue }
      members.append((name, type))
    }

    let mask = members.count > 0 ? (1 << members.count) - 1 : 0

    var `extension` = """
      extension \(type.trimmed): _XMLParsable {
        static func _buildMask() -> UInt64 {
          \(mask)
        }
                  
        static func _buildDump(partial: UnsafeMutableRawPointer, function: StaticString = #function) {
          let partial = partial.bindMemory(to: _XMLPartial<Self>.self, capacity: 1)
          let initialized = partial.pointer(to: \\.initialized)!.pointee
          print("fn: \\(function) obj: \\(partial) init: \\(String(initialized, radix: 2)) mask: \\(Self._buildMask())")
        }

        static func _buildPartial() -> UnsafeMutableRawPointer {
          let partial = UnsafeMutablePointer<_XMLPartial<Self>>.allocate(capacity: 1)
          let initialized = partial.pointer(to: \\.initialized)!
          initialized.pointee = Self._buildMask()
          Self._buildDump(partial: partial)
          return UnsafeMutableRawPointer(partial) 
        }

        static func _buildChild(name: UnsafePointer<CChar>) -> (any _XMLParsable.Type)? {
          // FIXME: replace with macro generated jump table or trie.
          // We shouldn't need to allocate here.
          let name = String(cString: name)
          switch name {

      """

    for (name, type) in members {
      `extension` += """
            case \"\(name)\":
              return \(type).self

        """
    }

    `extension` += """
          default:
            return nil
          }
        }

        static func _buildAny(partial: UnsafeMutableRawPointer, name: UnsafePointer<CChar>, value: Any) {
          Self._buildDump(partial: partial)
          // FIXME: replace with macro generated jump table or trie.
          // We shouldn't need to allocate here.
          let name = String(cString: name)
          switch (name, value) {

      """

    for index in members.indices {
      let (name, _) = members[index]
      `extension` += """
            case (\"\(name)\", let value as \(type)):
              fatalError("")

        """
    }

    `extension` += """
            default:
              preconditionFailure("Invalid build for unknown child")
            }
          }

          static func _buildIsFullyInitialized(partial: UnsafeMutableRawPointer) -> Bool {
            Self._buildDump(partial: partial)
            let partial = partial.bindMemory(to: _XMLPartial<Self>.self, capacity: 1)
            let initialized = partial.pointer(to: \\.initialized)!
            print("isFullyInitialized:", initialized.pointee == 0)
            return initialized.pointee == 0
          }

          static func _buildTakePartial(partial: UnsafeMutableRawPointer) -> Self {
            Self._buildDump(partial: partial)
            let partial = partial.bindMemory(to: _XMLPartial<Self>.self, capacity: 1)
            let value = partial.pointer(to: \\.value)!.move()
            partial.deallocate()
            return value
          }

          static func _buildDestroyPartial(partial: UnsafeMutableRawPointer) {
            Self._buildDump(partial: partial)
            let partial = partial.bindMemory(to: _XMLPartial<Self>.self, capacity: 1)
            let initialized = partial.pointer(to: \\.initialized)!.pointee
            let value = partial.pointer(to: \\.value)!

        """

    for index in members.indices {
      let (name, _) = members[index]
      `extension` += """
            if (initialized & (1 << \(index))) == 0 {
              let member = value.pointer(to: \\.\(name))!
              member.deinitialize(count: 1)
            }

        """
    }

    `extension` += """
          partial.deallocate()
        }
      
        static func _buildComplete(partial: UnsafeMutableRawPointer) throws -> Self {
          Self._buildDump(partial: partial)
          if _buildIsFullyInitialized(partial: partial) {
            return _buildTakePartial(partial: partial)
          } else {
            _buildDestroyPartial(partial: partial)
            throw XMLParseError.buildIncomplete
          }
        }

      """

//    for member in declaration.memberBlock.members {
//      guard
//        let decl = member.decl.as(VariableDeclSyntax.self),
//        let binding = decl.bindings.first,
//        let name = binding.pattern.as(IdentifierPatternSyntax.self)
//      else { continue }
//      var xmlAttribute = false
//      var xmlInlineElement = false
//
//      for attribute in decl.attributes {
//        guard case .attribute(let attribute) = attribute else { continue }
//        if attribute.attributeName.description == "XMLAttribute" {
//          xmlAttribute = true
//        }
//        if attribute.attributeName.description == "XMLInlineElement" {
//          xmlInlineElement = true
//        }
//      }
//
//      if xmlAttribute {
//        `extension` += """
//              self.\(name) = try element.decode(fromAttribute: "\(name)")
//
//          """
//      } else if xmlInlineElement {
//        `extension` += """
//              self.\(name) = try element.decode()
//
//          """
//      } else {
//        `extension` += """
//              self.\(name) = try element.decode(fromChild: "\(name)")
//
//          """
//      }
//    }

    `extension` += """
      }
      """
    print(`extension`)

    let decl = DeclSyntax(stringLiteral: `extension`)
    return [decl.as(ExtensionDeclSyntax.self)].compactMap { $0 }
  }
}
