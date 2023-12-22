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

  func test_decl_onlyStruct_broken() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8) var v: Int
      """,
      expandedSource: """
        var v: Int
        """,
      diagnostics: [
        // FIXME: https://github.com/apple/swift-syntax/issues/2206
      ],
      macros: Self.macros)
  }

  func test_members_storedVarDeclsAreAnnotated() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        var v1: Int
        @OtherAttribute var v2: Int
        var v3: Int { willSet {} }
      }
      """,
      expandedSource: """
        struct S {
          var v1: Int
          @OtherAttribute var v2: Int
          var v3: Int { willSet {} }
        }

        extension S: RegisterValue {
        }
        """,
      diagnostics: [
        .init(
          message: ErrorDiagnostic.expectedMemberAnnotatedWithMacro(bitFieldMacros).message,
          line: 3,
          column: 3,
          highlight: "var v1: Int"),
        .init(
          message: ErrorDiagnostic.expectedMemberAnnotatedWithMacro(bitFieldMacros).message,
          line: 4,
          column: 3,
          highlight: "@OtherAttribute var v2: Int"),
        .init(
          message: ErrorDiagnostic.expectedMemberAnnotatedWithMacro(bitFieldMacros).message,
          line: 5,
          column: 3,
          highlight: "var v3: Int { willSet {} }"),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_members_nonStoredVarDeclsAreOk() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        func f() {}
        class C {}
        var v: Void {}
        var v: Void { get {} }
        var v: Void { set {} }
        var v: Void { _read {} }
        var v: Void { _modify {} }
      }
      """,
      expandedSource: """
        struct S {
          func f() {}
          class C {}
          var v: Void {}
          var v: Void { get {} }
          var v: Void { set {} }
          var v: Void { _read {} }
          var v: Void { _modify {} }

          private init() {
            fatalError()
          }

          private var _never: Never

          struct Raw: RegisterValueRaw {
            typealias Value = S
            typealias Storage = UInt8
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }

          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = S
            var storage: UInt8
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }

          }
        }

        extension S: RegisterValue {
        }
        """,
      diagnostics: [],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_noFields() {
    // FIXME: see expanded source formatting
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {}
      """,
      expandedSource: """
        struct S {

          private init() {
            fatalError()
          }

          private var _never: Never

          struct Raw: RegisterValueRaw {
            typealias Value = S
            typealias Storage = UInt8
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }

          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = S
            var storage: UInt8
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }

          }}

        extension S: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_noTypedFields() {
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

          enum V1: ContiguousBitField {
            typealias Storage = UInt8
            static let bitRange = 0 ..< 1
          }

          enum V2: ContiguousBitField {
            typealias Storage = UInt8
            static let bitRange = 1 ..< 2
          }

          struct Raw: RegisterValueRaw {
            typealias Value = S
            typealias Storage = UInt8
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var v1: UInt8 {
              @inlinable @inline(__always) get {
                V1.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insert(newValue, into: &self.storage)
              }
            }
            var v2: UInt8 {
              @inlinable @inline(__always) get {
                V2.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insert(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = S
            var storage: UInt8
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }

          }
        }

        extension S: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_symmetric() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @ReadWrite(bits: 0..<1, as: Bool.self)
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

          enum V1: ContiguousBitField {
            typealias Storage = UInt8
            static let bitRange = 0 ..< 1
          }

          enum V2: ContiguousBitField {
            typealias Storage = UInt8
            static let bitRange = 1 ..< 2
          }

          struct Raw: RegisterValueRaw {
            typealias Value = S
            typealias Storage = UInt8
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var v1: UInt8 {
              @inlinable @inline(__always) get {
                V1.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insert(newValue, into: &self.storage)
              }
            }
            var v2: UInt8 {
              @inlinable @inline(__always) get {
                V2.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insert(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = S
            var storage: UInt8
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }
            var v1: Bool {
              @inlinable @inline(__always) get {
                preconditionMatchingBitWidth(V1.self, Bool.self)
                return Bool(storage: self.raw.v1)
              }
              @inlinable @inline(__always) set {
                preconditionMatchingBitWidth(V1.self, Bool.self)
                self.raw.v1 = newValue.storage(Self.Value.Raw.Storage.self)
              }
            }
          }
        }

        extension S: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_discontiguous() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @ReadWrite(bits: 0..<1, 3..<4, as: UInt8.self)
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

          enum V1: DiscontiguousBitField {
            typealias Storage = UInt8
            static let bitRanges = [0 ..< 1, 3 ..< 4]
          }

          struct Raw: RegisterValueRaw {
            typealias Value = S
            typealias Storage = UInt8
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var v1: UInt8 {
              @inlinable @inline(__always) get {
                V1.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insert(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = S
            var storage: UInt8
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }
            var v1: UInt8 {
              @inlinable @inline(__always) get {
                preconditionMatchingBitWidth(V1.self, UInt8.self)
                return UInt8(storage: self.raw.v1)
              }
              @inlinable @inline(__always) set {
                preconditionMatchingBitWidth(V1.self, UInt8.self)
                self.raw.v1 = newValue.storage(Self.Value.Raw.Storage.self)
              }
            }
          }
        }

        extension S: RegisterValue {
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
        @ReadOnly(bits: 0..<1, as: Bool.self)
        var v1: V1
        @WriteOnly(bits: 1..<2, as: Bool.self)
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

          enum V1: ContiguousBitField {
            typealias Storage = UInt8
            static let bitRange = 0 ..< 1
          }

          enum V2: ContiguousBitField {
            typealias Storage = UInt8
            static let bitRange = 1 ..< 2
          }

          struct Raw: RegisterValueRaw {
            typealias Value = S
            typealias Storage = UInt8
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.Read) {
              self.storage = value.storage
            }
            init(_ value: Value.Write) {
              self.storage = value.storage
            }
            var v1: UInt8 {
              @inlinable @inline(__always) get {
                V1.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insert(newValue, into: &self.storage)
              }
            }
            var v2: UInt8 {
              @inlinable @inline(__always) get {
                V2.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insert(newValue, into: &self.storage)
              }
            }
          }

          struct Read: RegisterValueRead {
            typealias Value = S
            var storage: UInt8
            init(_ value: Raw) {
              self.storage = value.storage
            }
            var v1: Bool {
              @inlinable @inline(__always) get {
                preconditionMatchingBitWidth(V1.self, Bool.self)
                return Bool(storage: self.raw.v1)
              }
            }
          }

          struct Write: RegisterValueWrite {
            typealias Value = S
            var storage: UInt8
            init(_ value: Raw) {
              self.storage = value.storage
            }
            init(_ value: Read) {
              // FIXME: mask off bits
              self.storage = value.storage
            }
            var v2: Bool {
              @available(*, deprecated, message: "API misuse; read from write view returns the value to be written, not the value initially read.")
              @inlinable @inline(__always) get {
                preconditionMatchingBitWidth(V2.self, Bool.self)
                return Bool(storage: self.raw.v2)
              }
              @inlinable @inline(__always) set {
                preconditionMatchingBitWidth(V2.self, Bool.self)
                self.raw.v2 = newValue.storage(Self.Value.Raw.Storage.self)
              }
            }
          }
        }

        extension S: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_otherRangeTypes0() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 32)
      struct OtherRangeTypes0 {
        @Reserved(bits: ...)
        var unbounded: Unbounded
      }
      """,
      expandedSource: """
        struct OtherRangeTypes0 {
          @available(*, unavailable)
          var unbounded: Unbounded {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          enum Unbounded: ContiguousBitField {
            typealias Storage = UInt32
            static let bitRange = 0 ..< 32
          }

          struct Raw: RegisterValueRaw {
            typealias Value = OtherRangeTypes0
            typealias Storage = UInt32
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var unbounded: UInt32 {
              @inlinable @inline(__always) get {
                Unbounded.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Unbounded.insert(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = OtherRangeTypes0
            var storage: UInt32
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }

          }
        }

        extension OtherRangeTypes0: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_otherRangeTypes1() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 32)
      struct OtherRangeTypes1 {
        @Reserved(bits: ...16)
        var partialThrough: PartialThrough
        @Reserved(bits: 17...)
        var partialFrom: PartialFrom
      }
      """,
      expandedSource: """
        struct OtherRangeTypes1 {
          @available(*, unavailable)
          var partialThrough: PartialThrough {
            get {
              fatalError()
            }
          }
          @available(*, unavailable)
          var partialFrom: PartialFrom {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          enum PartialThrough: ContiguousBitField {
            typealias Storage = UInt32
            static let bitRange = 0 ..< 17
          }

          enum PartialFrom: ContiguousBitField {
            typealias Storage = UInt32
            static let bitRange = 17 ..< 32
          }

          struct Raw: RegisterValueRaw {
            typealias Value = OtherRangeTypes1
            typealias Storage = UInt32
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var partialThrough: UInt32 {
              @inlinable @inline(__always) get {
                PartialThrough.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                PartialThrough.insert(newValue, into: &self.storage)
              }
            }
            var partialFrom: UInt32 {
              @inlinable @inline(__always) get {
                PartialFrom.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                PartialFrom.insert(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = OtherRangeTypes1
            var storage: UInt32
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }

          }
        }

        extension OtherRangeTypes1: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  func test_expansion_otherRangeTypes2() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 32)
      struct OtherRangeTypes2 {
        @Reserved(bits: ..<16)
        var partialUpTo: PartialUpTo
        @Reserved(bits: 16...31)
        var closed: Closed
      }
      """,
      expandedSource: """
        struct OtherRangeTypes2 {
          @available(*, unavailable)
          var partialUpTo: PartialUpTo {
            get {
              fatalError()
            }
          }
          @available(*, unavailable)
          var closed: Closed {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          enum PartialUpTo: ContiguousBitField {
            typealias Storage = UInt32
            static let bitRange = 0 ..< 16
          }

          enum Closed: ContiguousBitField {
            typealias Storage = UInt32
            static let bitRange = 16 ..< 32
          }

          struct Raw: RegisterValueRaw {
            typealias Value = OtherRangeTypes2
            typealias Storage = UInt32
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var partialUpTo: UInt32 {
              @inlinable @inline(__always) get {
                PartialUpTo.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                PartialUpTo.insert(newValue, into: &self.storage)
              }
            }
            var closed: UInt32 {
              @inlinable @inline(__always) get {
                Closed.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Closed.insert(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = OtherRangeTypes2
            var storage: UInt32
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }

          }
        }

        extension OtherRangeTypes2: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
