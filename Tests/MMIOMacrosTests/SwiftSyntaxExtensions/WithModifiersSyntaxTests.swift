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
import SwiftSyntaxBuilder
import Testing

@testable import MMIOMacros

struct WithModifiersSyntaxTests {
  struct AccessLevelTestVector: CustomStringConvertible {
    static let vectors: [Self] = [
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

    var description: String { "\(self.decl)" }
    var decl: any WithModifiersSyntax
    var accessLevel: DeclModifierSyntax?

    init(decl: DeclSyntax, accessLevel: DeclModifierSyntax?) {
      // swift-format-ignore: NeverForceUnwrap
      self.decl = decl.asProtocol((any WithModifiersSyntax).self)!
      self.accessLevel = accessLevel
    }
  }

  @Test(arguments: AccessLevelTestVector.vectors)
  func accessLevel(vector: AccessLevelTestVector) {
    #expect(
      vector.decl.accessLevel?.name.tokenKind
        == vector.accessLevel?.name.tokenKind)
  }
}
