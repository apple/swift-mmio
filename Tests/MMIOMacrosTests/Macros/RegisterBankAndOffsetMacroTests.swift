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

  func test_expansion() {
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
            @inlinable @inline(__always) get {
              #if FEATURE_INTERPOSABLE
              return .init(unsafeAddress: self.unsafeAddress + (0x0), interposer: self.interposer)
              #else
              return .init(unsafeAddress: self.unsafeAddress + (0x0))
              #endif
            }
          }
          var dr: Register<DR> {
            @inlinable @inline(__always) get {
              #if FEATURE_INTERPOSABLE
              return .init(unsafeAddress: self.unsafeAddress + (0x8), interposer: self.interposer)
              #else
              return .init(unsafeAddress: self.unsafeAddress + (0x8))
              #endif
            }
          }

          private (set) var unsafeAddress: UInt

          #if FEATURE_INTERPOSABLE
          var interposer: (any MMIOInterposer)?
          #endif

          #if FEATURE_INTERPOSABLE
          @inlinable @inline(__always)
          init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?) {
            self.unsafeAddress = unsafeAddress
            self.interposer = interposer
          }
          #else
          @inlinable @inline(__always)
          init(unsafeAddress: UInt) {
            self.unsafeAddress = unsafeAddress
          }
          #endif
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
