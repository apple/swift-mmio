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
import Testing

@testable import SVDMacros

struct XMLInlineElementMacroTests {
  static let macros: [String: Macro.Type] = [
    "XMLInlineElement": XMLMarkerMacro.self
  ]
  static let indentationWidth = Trivia.spaces(2)

  @Test func peerMacro_generatesNoPeers() {
    assertMacroExpansion(
      """
      struct S {
        @XMLInlineElement
        var v: V
      }
      """,
      expandedSource: """
        struct S {
          var v: V
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
