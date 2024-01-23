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
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import MMIOMacros

final class PatternBindingSyntaxTests: XCTestCase {
  func test_requireSimpleBindingIdentifier() {
    struct Vector {
      var decl: VariableDeclSyntax
      var identifier: IdentifierPatternSyntax?
      var file: StaticString
      var line: UInt

      init(
        decl: DeclSyntax,
        identifier: IdentifierPatternSyntax?,
        file: StaticString = #file,
        line: UInt = #line
      ) {
        self.decl = decl.as(VariableDeclSyntax.self)!
        self.identifier = identifier
        self.file = file
        self.line = line
      }
    }

    let vectors: [Vector] = [
      .init(
        decl: "var v: Int",
        identifier: .init(identifier: .identifier("v"))),
      .init(
        decl: "var _: Int",
        identifier: nil),
      .init(
        decl: "var (v, v): Int",
        identifier: nil),
    ]

    for vector in vectors {
      // FIXME: assert diagnostics
      let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
      do {
        let binding = try vector.decl.requireSingleBinding(context)
        let actual = try binding.requireSimpleBindingIdentifier(context)
        if let expected = vector.identifier {
          XCTAssertEqual(
            actual.description,
            expected.description,
            file: vector.file,
            line: vector.line)
        } else {
          XCTFail("unexpected identifier", file: vector.file, line: vector.line)
        }
      } catch {
        if vector.identifier != nil {
          XCTFail("expected identifier", file: vector.file, line: vector.line)
        }
      }
    }
  }

  func test_requireSimpleTypeIdentifier() {
    struct Vector {
      var decl: VariableDeclSyntax
      var type: String?
      var file: StaticString
      var line: UInt

      init(
        decl: DeclSyntax,
        type: String?,
        file: StaticString = #file,
        line: UInt = #line
      ) {
        self.decl = decl.as(VariableDeclSyntax.self)!
        self.type = type
        self.file = file
        self.line = line
      }
    }

    let vectors: [Vector] = [
      .init(
        decl: "var v: Int",
        type: "Int"),
      .init(
        decl: "var v: Swift.Int",
        type: "Swift.Int"),
      .init(
        decl: "var v: Register<Int>",
        type: "Register<Int>"),
      .init(
        decl: "var v: (Int, Int)",
        type: nil),
      .init(
        decl: "var v: Int?",
        type: nil),
      .init(
        decl: "var v: [Int]",
        type: nil),
      .init(
        decl: "var v",
        type: nil),
    ]

    for vector in vectors {
      // FIXME: assert diagnostics
      let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
      do {
        let binding = try vector.decl.requireSingleBinding(context)
        let actual = try binding.requireSimpleTypeIdentifier(context)
        if let expected = vector.type {
          XCTAssertEqual(
            actual.description,
            expected.description,
            file: vector.file,
            line: vector.line)
        } else {
          XCTFail("unexpected type", file: vector.file, line: vector.line)
        }
      } catch {
        if vector.type != nil {
          XCTFail("expected type", file: vector.file, line: vector.line)
        }
      }
    }
  }

  func test_requireNoAccessor() {
    struct Vector {
      var decl: VariableDeclSyntax
      var accessor: Bool
      var file: StaticString
      var line: UInt

      init(
        decl: DeclSyntax,
        accessor: Bool,
        file: StaticString = #file,
        line: UInt = #line
      ) {
        self.decl = decl.as(VariableDeclSyntax.self)!
        self.accessor = accessor
        self.file = file
        self.line = line
      }
    }

    let vectors: [Vector] = [
      .init(
        decl: "var v: Int",
        accessor: false),
      .init(
        decl: "var v: Int { willSet {} }",
        accessor: true),
      .init(
        decl: "var v: Int { didSet {} }",
        accessor: true),
      .init(
        decl: "var v: Void {}",
        accessor: true),
      .init(
        decl: "var v: Void { get {} }",
        accessor: true),
      .init(
        decl: "var v: Void { set {} }",
        accessor: true),
      .init(
        decl: "var v: Void { _read {} }",
        accessor: true),
      .init(
        decl: "var v: Void { _modify {} }",
        accessor: true),
    ]

    for vector in vectors {
      // FIXME: assert diagnostics
      let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
      do {
        let binding = try vector.decl.requireSingleBinding(context)
        try binding.requireNoAccessor(context)
        if vector.accessor {
          XCTFail("expected no accessor", file: vector.file, line: vector.line)
        }
      } catch {
        if !vector.accessor {
          XCTFail(
            "unexpected no accessor",
            file: vector.file,
            line: vector.line)
        }
      }
    }
  }
}
#endif
