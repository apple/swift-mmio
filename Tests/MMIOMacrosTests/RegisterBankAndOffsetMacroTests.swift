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
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import MMIOMacros

final class RegisterBankAndOffsetMacroTests: XCTestCase {
  static let macros: [String: Macro.Type] = [
    "RegisterBankType": RegisterBankMacro.self,
    "RegisterBank": RegisterBankOffsetMacro.self,
  ]
  static let indentationWidth = Trivia.spaces(2)

  func testPositiveExample() {
    assertMacroExpansion(
      """
      @RegisterBankType
      struct I2C {
        @RegisterBank(offset: 0x0)
        var control: Control
        @RegisterBank(offset: 0x8)
        var dr: Register<DR>
      }
      """,
      expandedSource: """
        struct I2C {
          var control: Control {
            @inline(__always) get {
              .init(unsafeAddress: self.unsafeAddress + (0x0))
            }
          }
          var dr: Register<DR> {
            @inline(__always) get {
              .init(unsafeAddress: self.unsafeAddress + (0x8))
            }
          }

          var unsafeAddress: UInt

          init(unsafeAddress: UInt) {
            self.unsafeAddress = unsafeAddress
          }
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
