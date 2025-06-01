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

@testable import SVDMacros

struct XMLElementMacroTests {
  static let macros: [String: SendableMacro.Type] = [
    "XMLAttribute": XMLMarkerMacro.self,
    "XMLElement": XMLElementMacro.self,
    "XMLInlineElement": XMLMarkerMacro.self,
  ]
  static let indentationWidth = Trivia.spaces(2)

  @Test func extensionMacro_generatesXMLElementInitializableConformance() {
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

        extension S: XMLElementInitializable {
          init(_ element: XMLElement) throws {
            self.v0 = try element.decode(fromChild: "v0")
            self.v1 = try element.decode(fromAttribute: "v1")
            self.v2 = try element.decode()
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
