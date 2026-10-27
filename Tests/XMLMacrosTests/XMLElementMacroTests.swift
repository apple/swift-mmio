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
import SwiftSyntaxMacros
import Testing

@testable import XMLMacros

struct XMLElementMacroTests {
  static let macros: [String: any SendableMacro.Type] = [
    "XMLAttribute": XMLMarkerMacro.self,
    "XMLElement": XMLElementMacro.self,
    "XMLInlineElement": XMLMarkerMacro.self,
  ]
  static let indentationWidth = Trivia.spaces(2)

  @Test func extensionMacro_generatesXMLElementDecodableConformance() {
    assertMacroExpansion(
      """
      @XMLElement
      struct S {
        var v0: V0
        @XMLAttribute
        var v1: V1
        @XMLInlineElement
        var v2: V2
      }
      """,
      expandedSource: """

        struct S {
          var v0: V0
          var v1: V1
          var v2: V2
        }

        extension S: XMLElementDecodable {
          public struct XMLBuilder: XMLElementBuilder {
            var v0 = XMLSlot<V0>()
            var v1 = XMLSlot<V1>()
            var v2 = V2.XMLBuilder()

            public init() {
            }

            public mutating func attribute(_ name: XMLName, _ value: XMLText) {
              switch name {
              case "v1":
                self.v1.decode(value)
              default:
                break
              }
              self.v2.attribute(name, value)
            }

            public static func child(
              _ name: XMLName,
              of builder: XMLBuilderPointer<Self>
            ) -> XMLFrame? {
              switch name {
              case "v0":
                return builder.decode(\\.v0)
              default:
                break
              }
              if let frame = V2.XMLBuilder.child(name, of: builder.member(\\.v2)) {
                return frame
              }
              return nil
            }

            public mutating func build() throws(XMLBuildError) -> S {
              try S(xmlBuilder: &self)
            }
          }

          init(xmlBuilder builder: inout XMLBuilder) throws(XMLBuildError) {
            self.v0 = try builder.v0.required("v0")
            self.v1 = try builder.v1.required("v1")
            self.v2 = try builder.v2.buildRequired()
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func extensionMacro_generatesSlotForEachKindOfMember() {
    assertMacroExpansion(
      """
      @XMLElement
      struct S {
        var v0: V0
        var v1: V1?
        var v2: [V2]
        var v3: [V3]?
        @XMLAttribute
        var v4: V4
        @XMLAttribute
        var v5: V5?
        @XMLInlineElement
        var v6: V6
        @XMLInlineElement
        var v7: V7?
      }
      """,
      expandedSource: """

        struct S {
          var v0: V0
          var v1: V1?
          var v2: [V2]
          var v3: [V3]?
          var v4: V4
          var v5: V5?
          var v6: V6
          var v7: V7?
        }

        extension S: XMLElementDecodable {
          public struct XMLBuilder: XMLElementBuilder {
            var v0 = XMLSlot<V0>()
            var v1 = XMLSlot<V1>()
            var v2 = XMLArraySlot<V2>()
            var v3 = XMLArraySlot<V3>()
            var v4 = XMLSlot<V4>()
            var v5 = XMLSlot<V5>()
            var v6 = V6.XMLBuilder()
            var v7 = V7.XMLBuilder()

            public init() {
            }

            public mutating func attribute(_ name: XMLName, _ value: XMLText) {
              switch name {
              case "v4":
                self.v4.decode(value)
              case "v5":
                self.v5.decode(value)
              default:
                break
              }
              self.v6.attribute(name, value)
              self.v7.attribute(name, value)
            }

            public static func child(
              _ name: XMLName,
              of builder: XMLBuilderPointer<Self>
            ) -> XMLFrame? {
              switch name {
              case "v0":
                return builder.decode(\\.v0)
              case "v1":
                return builder.decode(\\.v1)
              case "v2":
                return builder.decode(\\.v2)
              case "v3":
                return builder.decode(\\.v3)
              default:
                break
              }
              if let frame = V6.XMLBuilder.child(name, of: builder.member(\\.v6)) {
                return frame
              }
              if let frame = V7.XMLBuilder.child(name, of: builder.member(\\.v7)) {
                return frame
              }
              return nil
            }

            public mutating func build() throws(XMLBuildError) -> S {
              try S(xmlBuilder: &self)
            }
          }

          init(xmlBuilder builder: inout XMLBuilder) throws(XMLBuildError) {
            self.v0 = try builder.v0.required("v0")
            self.v1 = try builder.v1.optional()
            self.v2 = try builder.v2.get()
            self.v3 = try builder.v3.get()
            self.v4 = try builder.v4.required("v4")
            self.v5 = try builder.v5.optional()
            self.v6 = try builder.v6.buildRequired()
            self.v7 = try builder.v7.buildOptional()
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
