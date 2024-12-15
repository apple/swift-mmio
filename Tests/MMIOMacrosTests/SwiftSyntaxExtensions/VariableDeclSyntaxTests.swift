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

struct VariableDeclSyntaxTests {
  struct RequireBindingSpecifierTestVector: CustomStringConvertible {
    static let vectors: [Self] = [
      .init(decl: "var v: Int", bindingSpecifier: .var),
      .init(decl: "inout i: Int", bindingSpecifier: .inout),
      .init(decl: "let l: Int", bindingSpecifier: .let),
    ]

    var description: String { "\(self.decl)" }
    var decl: VariableDeclSyntax
    var bindingSpecifier: Keyword

    init(decl: DeclSyntax, bindingSpecifier: Keyword) {
      // swift-format-ignore: NeverForceUnwrap
      self.decl = decl.as(VariableDeclSyntax.self)!
      self.bindingSpecifier = bindingSpecifier
    }
  }

  @Test(arguments: RequireBindingSpecifierTestVector.vectors)
  func requireBindingSpecifier(vector: RequireBindingSpecifierTestVector) {
    // FIXME: assert diagnostics
    let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
    #expect(
      throws: Never.self,
      """
      expected \(vector.bindingSpecifier) binding specifier found \
      \(vector.decl.bindingSpecifier)
      """
    ) {
      try vector.decl.requireBindingSpecifier(vector.bindingSpecifier, context)
    }

    // FIXME: assert diagnostics
    guard vector.bindingSpecifier != .var else { return }
    #expect(
      throws: ExpansionError.self,
      """
      expected \(vector.bindingSpecifier) binding specifier found \
      \(vector.decl.bindingSpecifier)
      """
    ) {
      try vector.decl.requireBindingSpecifier(.var, context)
    }
  }

  struct RequireSingleBindingTestVector: CustomStringConvertible {
    static let vectors: [Self] = [
      .init(
        decl: "var v: Int",
        singleBinding: "v: Int"),
      .init(
        decl: "var _: Int",
        singleBinding: "_: Int"),
      .init(
        decl: "var (v, v): Int",
        singleBinding: "(v, v): Int"),
      .init(
        decl: "var v, w: Int",
        singleBinding: nil),
      .init(
        decl: "var v: Int, b: Int",
        singleBinding: nil),
    ]

    var description: String { "\(self.decl)" }
    var decl: VariableDeclSyntax
    var singleBinding: String?

    init(decl: DeclSyntax, singleBinding: String?) {
      // swift-format-ignore: NeverForceUnwrap
      self.decl = decl.as(VariableDeclSyntax.self)!
      self.singleBinding = singleBinding
    }
  }

  @Test(arguments: RequireSingleBindingTestVector.vectors)
  func requireSingleBinding(vector: RequireSingleBindingTestVector) {
    let context = MacroContext(Macro0.self, BasicMacroExpansionContext())
    let actual = try? vector.decl.requireSingleBinding(context)
    let expected = vector.singleBinding
    #expect(actual?.description == expected)
  }

  struct IsComputedPropertyTestVector: CustomStringConvertible {
    static let vectors: [Self] = [
      .init(decl: "var v: Int", isComputedProperty: false),
      .init(decl: "inout v: Int", isComputedProperty: false),
      .init(decl: "let v: Int", isComputedProperty: false),
      .init(decl: "var v, w: Int", isComputedProperty: false),
      .init(decl: "var v: Int, b: Int", isComputedProperty: false),
      .init(decl: "var _: Int", isComputedProperty: false),
      .init(decl: "var (v, w): Int", isComputedProperty: false),
      .init(decl: "var a", isComputedProperty: false),
      .init(decl: "var v: _", isComputedProperty: false),
      .init(decl: "var v: Int?", isComputedProperty: false),
      .init(decl: "var v: [Int]", isComputedProperty: false),
      .init(decl: "var v: (Int, Int)", isComputedProperty: false),
      .init(decl: "var v: Reg<T>", isComputedProperty: false),
      .init(decl: "var v: Swift.Int", isComputedProperty: false),
      .init(decl: "var v: Int { willSet {} }", isComputedProperty: false),
      .init(decl: "var v: Int { didSet {} }", isComputedProperty: false),
      .init(decl: "var v: Void {}", isComputedProperty: true),
      .init(decl: "var v: Void { get {} }", isComputedProperty: true),
      .init(decl: "var v: Void { set {} }", isComputedProperty: true),
      .init(decl: "var v: Void { _read {} }", isComputedProperty: true),
      .init(decl: "var v: Void { _modify {} }", isComputedProperty: true),
    ]

    var description: String { "\(self.decl)" }
    var decl: VariableDeclSyntax
    var isComputedProperty: Bool

    init(decl: DeclSyntax, isComputedProperty: Bool) {
      // swift-format-ignore: NeverForceUnwrap
      self.decl = decl.as(VariableDeclSyntax.self)!
      self.isComputedProperty = isComputedProperty
    }
  }

  @Test(arguments: IsComputedPropertyTestVector.vectors)
  func isComputedProperty(vector: IsComputedPropertyTestVector) {
    #expect(vector.decl.isComputedProperty == vector.isComputedProperty)
  }
}
#endif
