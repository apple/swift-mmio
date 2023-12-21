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
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import MMIOMacros

final class VariableDeclSyntaxTests: XCTestCase {
  func test_requireBindingSpecifier() {
    struct Vector {
      var decl: VariableDeclSyntax
      var bindingSpecifier: Keyword
      var file: StaticString
      var line: UInt

      init(
        decl: DeclSyntax,
        bindingSpecifier: Keyword,
        file: StaticString = #file,
        line: UInt = #line
      ) {
        self.decl = decl.as(VariableDeclSyntax.self)!
        self.bindingSpecifier = bindingSpecifier
        self.file = file
        self.line = line
      }
    }

    let vectors: [Vector] = [
      .init(decl: "var v: Int", bindingSpecifier: .var),
      .init(decl: "inout i: Int", bindingSpecifier: .inout),
      .init(decl: "let l: Int", bindingSpecifier: .let),
    ]

    for vector in vectors {
      // FIXME: assert diagnostics
      let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
      do {
        try vector.decl.requireBindingSpecifier(
          vector.bindingSpecifier, context)
      } catch {
        XCTFail(
          """
          expected \(vector.bindingSpecifier) binding specifier found \
          \(vector.decl.bindingSpecifier)
          """,
          file: vector.file,
          line: vector.line)
      }

      guard vector.bindingSpecifier != .var else { continue }
      do {
        try vector.decl.requireBindingSpecifier(.var, context)
        XCTFail(
          """
          expected \(vector.bindingSpecifier) binding specifier found \
          \(vector.decl.bindingSpecifier)
          """,
          file: vector.file,
          line: vector.line)
      } catch {
        // FIXME: assert diagnostics
      }
    }
  }

  func test_requireSingleBinding() {
    struct Vector {
      var decl: VariableDeclSyntax
      var singleBinding: PatternBindingSyntax?
      var file: StaticString
      var line: UInt

      init(
        decl: DeclSyntax,
        singleBinding: PatternBindingSyntax?,
        file: StaticString = #file,
        line: UInt = #line
      ) {
        self.decl = decl.as(VariableDeclSyntax.self)!
        self.singleBinding = singleBinding
        self.file = file
        self.line = line
      }
    }

    let vectors: [Vector] = [
      .init(
        decl: "var v: Int",
        singleBinding: .init(
          pattern: IdentifierPatternSyntax(identifier: .identifier("v")),
          typeAnnotation: TypeAnnotationSyntax(
            colon: .colonToken(trailingTrivia: .space),
            type: IdentifierTypeSyntax(name: .identifier("Int"))))),
      .init(
        decl: "var _: Int",
        singleBinding: .init(
          pattern: WildcardPatternSyntax(),
          typeAnnotation: TypeAnnotationSyntax(
            colon: .colonToken(trailingTrivia: .space),
            type: IdentifierTypeSyntax(name: .identifier("Int"))))),
      .init(
        decl: "var (v, w): Int",
        singleBinding: .init(
          pattern: TuplePatternSyntax(elements: [
            TuplePatternElementSyntax(
              pattern: IdentifierPatternSyntax(identifier: .identifier("v")),
              trailingComma: .commaToken(trailingTrivia: .space)),
            TuplePatternElementSyntax(
              pattern: IdentifierPatternSyntax(identifier: .identifier("w"))),
          ]),
          typeAnnotation: TypeAnnotationSyntax(
            colon: .colonToken(trailingTrivia: .space),
            type: IdentifierTypeSyntax(name: .identifier("Int"))))),
      .init(
        decl: "var v, w: Int",
        singleBinding: nil),
      .init(
        decl: "var v: Int, b: Int",
        singleBinding: nil),
    ]

    for vector in vectors {
      let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
      do {
        let actual = try vector.decl.requireSingleBinding(context)
        if let expected = vector.singleBinding {
          XCTAssertEqual(
            actual.description,
            expected.description,
            file: vector.file,
            line: vector.line)
        } else {
          XCTFail("expected no binding", file: vector.file, line: vector.line)
        }
      } catch {
        if vector.singleBinding != nil {
          XCTFail("expected binding", file: vector.file, line: vector.line)
        }
      }
    }
  }
}
