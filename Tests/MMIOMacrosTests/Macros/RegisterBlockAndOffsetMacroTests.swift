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
import SwiftSyntaxMacros
import Testing

@testable import MMIOMacros

struct RegisterBlockAndOffsetMacroTests {
  static let scalarMacros: [String: Macro.Type] = [
    "RegisterBlockType": RegisterBlockMacro.self,
    "RegisterBlock": RegisterBlockScalarMemberMacro.self,
  ]

  static let arrayMacros: [String: Macro.Type] = [
    "RegisterBlockType": RegisterBlockMacro.self,
    "RegisterBlock": RegisterBlockArrayMemberMacro.self,
  ]

  static let indentationWidth = Trivia.spaces(2)

  @Test func expansion_scalarMembers() {
    assertMacroExpansion(
      """
      @RegisterBlockType
      struct I2C {
        @RegisterBlock(offset: 0x0)
        var control: Control
        @RegisterBlock(offset: 0x8)
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

          let unsafeAddress: UInt

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

        extension I2C: RegisterProtocol {
        }
        """,
      macros: Self.scalarMacros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func expansion_arrayMembers() {
    assertMacroExpansion(
      """
      @RegisterBlockType
      struct I2C {
        @RegisterBlock(offset: 0x000, stride: 0x10, count: 0x08)
        var control: Control
        @RegisterBlock(offset: 0x100, stride: 0x10, count: 0x10)
        var dr: Register<DR>
      }
      """,
      expandedSource: """
        struct I2C {
          var control: Control {
            @inlinable @inline(__always) get {
              #if FEATURE_INTERPOSABLE
              return .init(unsafeAddress: self.unsafeAddress + (0x000), stride: 0x10, count: 0x08, interposer: self.interposer)
              #else
              return .init(unsafeAddress: self.unsafeAddress + (0x000), stride: 0x10, count: 0x08)
              #endif
            }
          }
          var dr: Register<DR> {
            @inlinable @inline(__always) get {
              #if FEATURE_INTERPOSABLE
              return .init(unsafeAddress: self.unsafeAddress + (0x100), stride: 0x10, count: 0x10, interposer: self.interposer)
              #else
              return .init(unsafeAddress: self.unsafeAddress + (0x100), stride: 0x10, count: 0x10)
              #endif
            }
          }

          let unsafeAddress: UInt

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

        extension I2C: RegisterProtocol {
        }
        """,
      macros: Self.arrayMacros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func accessLevel_propagation() {
    assertMacroExpansion(
      """
      @RegisterBlockType
      public struct I2C {
        @RegisterBlock(offset: 0x0)
        var control: Control
        @RegisterBlock(offset: 0x8)
        var dr: Register<DR>
      }
      """,
      expandedSource: """
        public struct I2C {
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

          public let unsafeAddress: UInt

          #if FEATURE_INTERPOSABLE
          public var interposer: (any MMIOInterposer)?
          #endif

          #if FEATURE_INTERPOSABLE
          @inlinable @inline(__always)
          public init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?) {
            self.unsafeAddress = unsafeAddress
            self.interposer = interposer
          }
          #else
          @inlinable @inline(__always)
          public init(unsafeAddress: UInt) {
            self.unsafeAddress = unsafeAddress
          }
          #endif
        }

        extension I2C: RegisterProtocol {
        }
        """,
      macros: Self.scalarMacros,
      indentationWidth: Self.indentationWidth)
  }
}
#endif
