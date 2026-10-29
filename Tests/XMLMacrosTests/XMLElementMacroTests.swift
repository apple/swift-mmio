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

  @Test func extensionMacro_generatesXMLStructDecodableConformance() {
    assertMacroExpansion(
      """
      @XMLElement
      struct S {
        var v0: V0
        @XMLAttribute
        var v1: V1?
        @XMLInlineElement
        var v2: V2
        var v3: [V3]?
      }
      """,
      expandedSource: """
        struct S {
          var v0: V0
          var v1: V1?
          var v2: V2
          var v3: [V3]?
        }

        extension S: XMLStructDecodable {
          public struct Fields: XMLFields {
            var v0: V0? = nil
            var v1: V1? = nil
            var v3: [V3] = []
            var v2 = V2.Fields()

            public init() {
            }

            public static var slotCount: Int {
              3 + V2.Fields.slotCount
            }

            @inline(__always)
            public static func slot(
              for field: borrowing some CommonFieldDecoder & ~Escapable
            ) -> Int {
              if field.matches("v0") {
                return 0
              }
              if field.matches("@v1") {
                return 1
              }
              if field.matches("v3") {
                return 2
              }
              let v2 = V2.Fields.slot(for: field)
              if v2 >= 0 {
                return 3 + v2
              }
              return -1
            }

            public mutating func decode(
              slot: Int, from decoder: inout some CommonDecoder & ~Escapable
            ) throws(CodingError.Decoding) {
              switch slot {
              case 0:
                if self.v0 == nil {
                  self.v0 = try decoder.decode(V0.self)
                }
              case 1:
                if self.v1 == nil {
                  self.v1 = try decoder.decode(V1.self)
                }
              case 2:
                self.v3.append(try decoder.decode(V3.self))
              default:
                if slot < 3 + V2.Fields.slotCount {
                  try self.v2.decode(slot: slot - 3, from: &decoder)
                  return
                }
                return
              }
            }

            public consuming func build() throws(CodingError.Decoding) -> S? {
              guard let v0 = self.v0 else {
                return nil
              }
              guard let v2 = try self.v2.build() else {
                return nil
              }
              return S(v0: v0, v1: self.v1, v2: v2, v3: self.v3)
            }
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
