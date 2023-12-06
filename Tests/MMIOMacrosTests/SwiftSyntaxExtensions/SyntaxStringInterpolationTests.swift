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
import XCTest

@testable import MMIOMacros

final class SyntaxStringInterpolationTests: XCTestCase {
  func test_appendInterpolationNodeTrailingTrivia_none() {
    let expected: DeclSyntax = "struct S {}"
    let acl: DeclModifierSyntax? = nil
    let actual: DeclSyntax = "\(acl, trailingTrivia: .spaces(2))struct S {}"
    XCTAssertEqual(expected.description, actual.description)
  }

  func test_appendInterpolationNodeTrailingTrivia_some() {
    let expected: DeclSyntax = "private  struct S {}"
    let acl: DeclModifierSyntax? = .init(name: .keyword(.private))
    let actual: DeclSyntax = "\(acl, trailingTrivia: .spaces(2))struct S {}"
    XCTAssertEqual(expected.description, actual.description)
  }

  func test_appendInterpolationNodesIntermediateTrivia_none() {
    let expected: DeclSyntax = "struct S {}"
    let decls: [DeclSyntax] = []
    let actual: DeclSyntax = "struct S {\(decls, intermediateTrivia: .newlines(2))}"
    XCTAssertEqual(expected.description, actual.description)
  }

  func test_appendInterpolationNodesIntermediateTrivia_one() {
    let expected: DeclSyntax = """
      struct S {
      var x = 1
      }
      """
    let decls: [DeclSyntax] = ["var x = 1"]
    let actual: DeclSyntax = """
      struct S {
      \(decls, intermediateTrivia: .newlines(2))
      }
      """
    XCTAssertEqual(expected.description, actual.description)
  }

  func test_appendInterpolationNodesIntermediateTrivia_many() {
    let expected: DeclSyntax = """
      struct S {
      var x = 1

      var y = 2
      }
      """
    let decls: [DeclSyntax] = ["var x = 1", "var y = 2"]
    let actual: DeclSyntax = """
      struct S {
      \(decls, intermediateTrivia: .newlines(2))
      }
      """
    XCTAssertEqual(expected.description, actual.description)
  }
}
