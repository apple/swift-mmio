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
import XCTest

@testable import MMIOMacros

final class WithModifiersSyntaxTests: XCTestCase {
  @Test func accessLevel() {
    struct Vector {
      var decl: any WithModifiersSyntax
      var accessLevel: DeclModifierSyntax?
      var file: StaticString
      var line: UInt

      init(
        decl: DeclSyntax,
        accessLevel: DeclModifierSyntax?,
        file: StaticString = #file,
        line: UInt = #line
      ) {
        self.decl = decl.asProtocol(WithModifiersSyntax.self)!
        self.accessLevel = accessLevel
        self.file = file
        self.line = line
      }
    }

    let vectors: [Vector] = [
      .init(
        decl: "final class C {}",
        accessLevel: nil),
      .init(
        decl: "final open class C {}",
        accessLevel: .init(name: .keyword(.open))),
      .init(
        decl: "final public class C {}",
        accessLevel: .init(name: .keyword(.public))),
      .init(
        decl: "final package class C {}",
        accessLevel: .init(name: .keyword(.package))),
      .init(
        decl: "final internal class C {}",
        accessLevel: .init(name: .keyword(.internal))),
      .init(
        decl: "final fileprivate class C {}",
        accessLevel: .init(name: .keyword(.fileprivate))),
      .init(
        decl: "final private class C {}",
        accessLevel: .init(name: .keyword(.private))),
      .init(
        decl: "final private public class C {}",
        accessLevel: .init(name: .keyword(.private))),
    ]

    for vector in vectors {
      XCTAssertEqual(
        vector.decl.accessLevel?.name.tokenKind,
        vector.accessLevel?.name.tokenKind)
    }
  }
}
#endif
