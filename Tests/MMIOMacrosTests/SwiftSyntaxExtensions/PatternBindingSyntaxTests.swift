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
import Testing

@testable import MMIOMacros

struct PatternBindingSyntaxTests {
  struct RequireSimpleBindingIdentifierTestVector {
    static let vectors: [Self] = [
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

    var decl: VariableDeclSyntax
    var identifier: IdentifierPatternSyntax?

    init(
      decl: DeclSyntax,
      identifier: IdentifierPatternSyntax?
    ) {
      self.decl = decl.as(VariableDeclSyntax.self)!
      self.identifier = identifier
    }
  }

  @Test(arguments: RequireSimpleBindingIdentifierTestVector.vectors)
  func requireSimpleBindingIdentifier(vector: RequireSimpleBindingIdentifierTestVector) {
    // FIXME: assert diagnostics
    let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
    let binding = try? vector.decl.requireSingleBinding(context)
    let actual = try? binding?.requireSimpleBindingIdentifier(context)
    let expected = vector.identifier
    #expect(actual?.description == expected?.description)
  }

  struct RequireSimpleTypeIdentifierTestVector {
    static let vectors: [Self] = [
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

    var decl: VariableDeclSyntax
    var type: String?

    init(
      decl: DeclSyntax,
      type: String?
    ) {
      self.decl = decl.as(VariableDeclSyntax.self)!
      self.type = type
    }
  }

  @Test(arguments: RequireSimpleTypeIdentifierTestVector.vectors)
  func requireSimpleTypeIdentifier(vector: RequireSimpleTypeIdentifierTestVector) {
    // FIXME: assert diagnostics
    let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
    let binding = try? vector.decl.requireSingleBinding(context)
    let actual = try? binding?.requireSimpleTypeIdentifier(context)
    let expected = vector.type
    #expect(actual?.description == expected?.description)
  }

  struct RequireNoAccessorTestVector {
    static let vectors: [Self] = [
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

    var decl: VariableDeclSyntax
    var accessor: Bool

    init(
      decl: DeclSyntax,
      accessor: Bool
    ) {
      self.decl = decl.as(VariableDeclSyntax.self)!
      self.accessor = accessor
    }
  }

  @Test(arguments: RequireNoAccessorTestVector.vectors)
  func requireNoAccessor(vector: RequireNoAccessorTestVector) {
    // FIXME: assert diagnostics
    let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
    let binding = try? vector.decl.requireSingleBinding(context)
    let accessor = (try? binding?.requireNoAccessor(context)) == nil
    #expect(accessor == vector.accessor)
  }
}
#endif
