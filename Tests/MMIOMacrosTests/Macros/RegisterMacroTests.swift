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

final class RegisterMacroTests: XCTestCase {
  typealias ErrorDiagnostic = MMIOMacros.ErrorDiagnostic<RegisterMacro>

  static let macros: [String: Macro.Type] = [
    "Register": RegisterMacro.self,
    "Reserved": ReservedMacro.self,
    "ReadWrite": ReadWriteMacro.self,
    "ReadOnly": ReadOnlyMacro.self,
    "WriteOnly": WriteOnlyMacro.self,
  ]
  static let indentationWidth = Trivia.spaces(2)

  // FIXME: test bitwidths parsing/allowed widths

  func test_decl_onlyStruct() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8) actor A {}
      @Register(bitWidth: 0x8) class C {}
      @Register(bitWidth: 0x8) enum E {}
      """,
      expandedSource: """
        actor A {}
        class C {}
        enum E {}
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 1,
          column: 26,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "actor "),
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 2,
          column: 26,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "class "),
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 3,
          column: 26,
          // FIXME: https://github.com/apple/swift-syntax/pull/2213
          highlight: "enum "),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_members_onlyVarDecls() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        func f() {}
        class C {}
      }
      """,
      expandedSource: """
        struct S {
          func f() {}
          class C {}
        }

        extension S: RegisterLayout {
        }
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.onlyMemberVarDecls().message,
          line: 3,
          column: 3,
          // FIXME: Improve this highlight
          highlight: "func f() {}"),
        .init(
          message: ErrorDiagnostic.onlyMemberVarDecls().message,
          line: 4,
          column: 3,
          // FIXME: Improve this highlight
          highlight: "class C {}"),

      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_members_varDeclsAreAnnotated() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        var v1: Int
        @OtherAttribute var v2: Int
      }
      """,
      expandedSource: """
        struct S {
          var v1: Int
          @OtherAttribute var v2: Int
        }

        extension S: RegisterLayout {
        }
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedMemberAnnotatedWithOneOf(bitFieldMacros).message,
          line: 3,
          column: 3,
          highlight: "var v1: Int"),
        .init(
          message: ErrorDiagnostic.expectedMemberAnnotatedWithOneOf(bitFieldMacros).message,
          line: 4,
          column: 3,
          highlight: "@OtherAttribute var v2: Int"),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_symmetric() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @ReadWrite(bits: 0..<1)
        var v1: V1
        @Reserved(bits: 1..<2)
        var v2: V2
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var v1: V1 {
            get {
              fatalError()
            }
          }
          @available(*, unavailable)
          var v2: V2 {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          enum V1: BitField {
            typealias RawStorage = UInt8
            static let bitRange = 0 ..< 1
          }

          enum V2: BitField {
            typealias RawStorage = UInt8
            static let bitRange = 1 ..< 2
          }

          struct Raw: RegisterLayoutRaw {
            typealias MMIOVolatileRepresentation = UInt8
            typealias Layout = S
            var _rawStorage: UInt8
            init(_ value: Layout.ReadWrite) {
              self._rawStorage = value._rawStorage
            }
            var v1: UInt8 {
              @inline(__always) get {
                self._rawStorage[bits: V1.bitRange]
              }
              @inline(__always) set {
                self._rawStorage[bits: V1.bitRange] = newValue
              }
            }
            var v2: UInt8 {
              @inline(__always) get {
              self._rawStorage[bits: V2.bitRange]
            }
              @inline(__always) set {
              self._rawStorage[bits: V2.bitRange] = newValue
            }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterLayoutRead, RegisterLayoutWrite {
            typealias MMIOVolatileRepresentation = UInt8
            typealias Layout = S
            var _rawStorage: UInt8
            init(_ value: ReadWrite) {
              self._rawStorage = value._rawStorage
            }
            init(_ value: Raw) {
              self._rawStorage = value._rawStorage
            }
            var v1: UInt8 {
              @inline(__always) get {
                self._rawStorage[bits: V1.bitRange]
              }
              @inline(__always) set {
                self._rawStorage[bits: V1.bitRange] = newValue
              }
            }
          }
        }

        extension S: RegisterLayout {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_asymmetric() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @ReadWrite(bits: 0..<1)
        var v1: V1
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var v1: V1 {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          enum V1: BitField {
            typealias RawStorage = UInt8
            static let bitRange = 0 ..< 1
          }

          struct Raw: RegisterLayoutRaw {
            typealias MMIOVolatileRepresentation = UInt8
            typealias Layout = S
            var _rawStorage: UInt8
            init(_ value: Layout.ReadWrite) {
              self._rawStorage = value._rawStorage
            }
            var v1: UInt8 {
              @inline(__always) get {
                self._rawStorage[bits: V1.bitRange]
              }
              @inline(__always) set {
                self._rawStorage[bits: V1.bitRange] = newValue
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterLayoutRead, RegisterLayoutWrite {
            typealias MMIOVolatileRepresentation = UInt8
            typealias Layout = S
            var _rawStorage: UInt8
            init(_ value: ReadWrite) {
              self._rawStorage = value._rawStorage
            }
            init(_ value: Raw) {
              self._rawStorage = value._rawStorage
            }
            var v1: UInt8 {
              @inline(__always) get {
                self._rawStorage[bits: V1.bitRange]
              }
              @inline(__always) set {
                self._rawStorage[bits: V1.bitRange] = newValue
              }
            }
          }
        }

        extension S: RegisterLayout {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
