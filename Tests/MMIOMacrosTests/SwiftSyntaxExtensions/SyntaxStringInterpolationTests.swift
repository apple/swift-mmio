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

#if canImport(MMIOMacros)
import SwiftSyntax
import Testing

@testable import MMIOMacros

struct SyntaxStringInterpolationTests {
  @Test func appendInterpolationNodesIntermediateTrivia_none() {
    let expected: DeclSyntax = "struct S {}"
    let decls: [DeclSyntax] = []
    let actual: DeclSyntax =
      "struct S {\(nodes: decls, intermediateTrivia: .newlines(2))}"
    #expect(expected.description == actual.description)
  }

  @Test func appendInterpolationNodesIntermediateTrivia_one() {
    let expected: DeclSyntax = """
      struct S {
      var x = 1
      }
      """
    let decls: [DeclSyntax] = ["var x = 1"]
    let actual: DeclSyntax = """
      struct S {
      \(nodes: decls, intermediateTrivia: .newlines(2))
      }
      """
    #expect(expected.description == actual.description)
  }

  @Test func appendInterpolationNodesIntermediateTrivia_many() {
    let expected: DeclSyntax = """
      struct S {
      var x = 1

      var y = 2
      }
      """
    let decls: [DeclSyntax] = ["var x = 1", "var y = 2"]
    let actual: DeclSyntax = """
      struct S {
      \(nodes: decls, intermediateTrivia: .newlines(2))
      }
      """
    #expect(expected.description == actual.description)
  }
}
#endif
