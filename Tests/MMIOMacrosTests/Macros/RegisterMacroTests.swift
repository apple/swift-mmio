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

#if canImport(MMIOMacros)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import MMIOMacros

struct RegisterMacroTests {
  typealias ErrorDiagnostic = MMIOMacros.ErrorDiagnostic<RegisterMacro>

  static let macros: [String: any SendableMacro.Type] = [
    "Register": RegisterMacro.self,
    "Reserved": ReservedMacro.self,
    "ReadWrite": ReadWriteMacro.self,
    "ReadOnly": ReadOnlyMacro.self,
    "WriteOnly": WriteOnlyMacro.self,
  ]
  static let indentationWidth = Trivia.spaces(2)

  // FIXME: test bitwidths parsing/allowed widths

  @Test func decl_onlyStruct() {
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
          highlights: ["actor"]),
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 2,
          column: 26,
          highlights: ["class"]),
        .init(
          message: ErrorDiagnostic.expectedDecl(StructDeclSyntax.self).message,
          line: 3,
          column: 26,
          highlights: ["enum"]),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func decl_onlyStruct_broken() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8) var v: Int
      """,
      expandedSource: """
        var v: Int
        """,
      diagnostics: [
        // FIXME: https://github.com/swiftlang/swift-syntax/issues/2206
      ],
      macros: Self.macros)
  }

  @Test func members_storedVarDeclsAreAnnotated() {
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
          message: ErrorDiagnostic.expectedMemberAnnotatedWithMacro(
            bitFieldMacros
          ).message,
          line: 3,
          column: 3,
          highlights: ["var v1: Int"],
          fixIts: [
            .init(message: "Insert '@Reserved(bits:as:)' macro"),
            .init(message: "Insert '@ReadWrite(bits:as:)' macro"),
            .init(message: "Insert '@ReadOnly(bits:as:)' macro"),
            .init(message: "Insert '@WriteOnly(bits:as:)' macro"),
          ]),
        .init(
          message: ErrorDiagnostic.expectedMemberAnnotatedWithMacro(
            bitFieldMacros
          ).message,
          line: 4,
          column: 3,
          highlights: ["@OtherAttribute var v2: Int"],
          fixIts: [
            .init(message: "Insert '@Reserved(bits:as:)' macro"),
            .init(message: "Insert '@ReadWrite(bits:as:)' macro"),
            .init(message: "Insert '@ReadOnly(bits:as:)' macro"),
            .init(message: "Insert '@WriteOnly(bits:as:)' macro"),
          ]),
        .init(
          message: ErrorDiagnostic.expectedMemberAnnotatedWithMacro(
            bitFieldMacros
          ).message,
          line: 5,
          column: 3,
          highlights: ["var v3: Int { willSet {} }"],
          fixIts: [
            .init(message: "Insert '@Reserved(bits:as:)' macro"),
            .init(message: "Insert '@ReadWrite(bits:as:)' macro"),
            .init(message: "Insert '@ReadOnly(bits:as:)' macro"),
            .init(message: "Insert '@WriteOnly(bits:as:)' macro"),
          ]),
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func members_nonStoredVarDeclsAreOk() {
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

  @Test func expansion_noFields() {
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

          }
        }

        extension S: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func expansion_noTypedFields() {
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

          typealias V1 = _MMIOBitField<Self, UInt8, Never, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRangeEnd>>

          typealias V2 = _MMIOBitField<Self, UInt8, Never, _MMIOBitFieldRange<1, 2, _MMIOBitFieldRangeEnd>>

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
                V1.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insertBits(newValue, into: &self.storage)
              }
            }
            var v2: UInt8 {
              @inlinable @inline(__always) get {
                V2.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insertBits(newValue, into: &self.storage)
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

  @Test func expansion_symmetric() {
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

          typealias V1 = _MMIOBitField<Self, UInt8, Bool, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRangeEnd>>

          typealias V2 = _MMIOBitField<Self, UInt8, Never, _MMIOBitFieldRange<1, 2, _MMIOBitFieldRangeEnd>>

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
                V1.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insertBits(newValue, into: &self.storage)
              }
            }
            var v2: UInt8 {
              @inlinable @inline(__always) get {
                V2.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insertBits(newValue, into: &self.storage)
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
                V1.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insert(newValue, into: &self.storage)
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

  @Test func expansion_discontiguous() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @ReadWrite(bits: 0..<1, 3..<4, as: UInt16.self)
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

          typealias V1 = _MMIOBitField<Self, UInt8, UInt16, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRange<3, 4, _MMIOBitFieldRangeEnd>>>

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
                V1.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insertBits(newValue, into: &self.storage)
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
            var v1: UInt16 {
              @inlinable @inline(__always) get {
                V1.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insert(newValue, into: &self.storage)
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

  @Test func expansion_discontiguousSingleBits() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @ReadWrite(bits: 0, 3, as: UInt16.self)
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

          typealias V1 = _MMIOBitField<Self, UInt8, UInt16, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRange<3, 4, _MMIOBitFieldRangeEnd>>>

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
                V1.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insertBits(newValue, into: &self.storage)
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
            var v1: UInt16 {
              @inlinable @inline(__always) get {
                V1.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insert(newValue, into: &self.storage)
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

  @Test func expansion_discontiguousIndicesAndRanges() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @ReadWrite(bits: 0, 2..<4, as: UInt8.self)
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

          typealias V1 = _MMIOBitField<Self, UInt8, UInt8, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRange<2, 4, _MMIOBitFieldRangeEnd>>>

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
                V1.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insertBits(newValue, into: &self.storage)
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
                V1.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insert(newValue, into: &self.storage)
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

  @Test func expansion_asymmetric() {
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

          typealias V1 = _MMIOBitField<Self, UInt8, Bool, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRangeEnd>>

          typealias V2 = _MMIOBitField<Self, UInt8, Bool, _MMIOBitFieldRange<1, 2, _MMIOBitFieldRangeEnd>>

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
                V1.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insertBits(newValue, into: &self.storage)
              }
            }
            var v2: UInt8 {
              @inlinable @inline(__always) get {
                V2.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insertBits(newValue, into: &self.storage)
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
                V1.extract(from: self.storage)
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
                V2.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insert(newValue, into: &self.storage)
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

  @Test func expansion_otherRangeTypes0() {
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

          typealias Unbounded = _MMIOBitField<Self, UInt32, Never, _MMIOBitFieldRange<0, 32, _MMIOBitFieldRangeEnd>>

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
                Unbounded.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Unbounded.insertBits(newValue, into: &self.storage)
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

  @Test func expansion_otherRangeTypes1() {
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

          typealias PartialThrough = _MMIOBitField<Self, UInt32, Never, _MMIOBitFieldRange<0, 17, _MMIOBitFieldRangeEnd>>

          typealias PartialFrom = _MMIOBitField<Self, UInt32, Never, _MMIOBitFieldRange<17, 32, _MMIOBitFieldRangeEnd>>

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
                PartialThrough.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                PartialThrough.insertBits(newValue, into: &self.storage)
              }
            }
            var partialFrom: UInt32 {
              @inlinable @inline(__always) get {
                PartialFrom.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                PartialFrom.insertBits(newValue, into: &self.storage)
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

  @Test func expansion_otherRangeTypes2() {
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

          typealias PartialUpTo = _MMIOBitField<Self, UInt32, Never, _MMIOBitFieldRange<0, 16, _MMIOBitFieldRangeEnd>>

          typealias Closed = _MMIOBitField<Self, UInt32, Never, _MMIOBitFieldRange<16, 32, _MMIOBitFieldRangeEnd>>

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
                PartialUpTo.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                PartialUpTo.insertBits(newValue, into: &self.storage)
              }
            }
            var closed: UInt32 {
              @inlinable @inline(__always) get {
                Closed.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Closed.insertBits(newValue, into: &self.storage)
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

  @Test func expansion_singleBit() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 32)
      struct SingleBit {
        @Reserved(bits: 0)
        var low: Low
        @Reserved(bits: 31)
        var high: High
      }
      """,
      expandedSource: """
        struct SingleBit {
          @available(*, unavailable)
          var low: Low {
            get {
              fatalError()
            }
          }
          @available(*, unavailable)
          var high: High {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          typealias Low = _MMIOBitField<Self, UInt32, Never, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRangeEnd>>

          typealias High = _MMIOBitField<Self, UInt32, Never, _MMIOBitFieldRange<31, 32, _MMIOBitFieldRangeEnd>>

          struct Raw: RegisterValueRaw {
            typealias Value = SingleBit
            typealias Storage = UInt32
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var low: UInt32 {
              @inlinable @inline(__always) get {
                Low.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Low.insertBits(newValue, into: &self.storage)
              }
            }
            var high: UInt32 {
              @inlinable @inline(__always) get {
                High.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                High.insertBits(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = SingleBit
            var storage: UInt32
            init(_ value: ReadWrite) {
              self.storage = value.storage
            }
            init(_ value: Raw) {
              self.storage = value.storage
            }

          }
        }

        extension SingleBit: RegisterValue {
        }
        """,
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func accessLevel_propagation() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      public struct S {
        @ReadOnly(bits: 0..<1, as: Bool.self)
        var v1: V1
        @WriteOnly(bits: 1..<2, as: Bool.self)
        var v2: V2
      }
      """,
      expandedSource: """
        public struct S {
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

          public typealias V1 = _MMIOBitField<Self, UInt8, Bool, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRangeEnd>>

          public typealias V2 = _MMIOBitField<Self, UInt8, Bool, _MMIOBitFieldRange<1, 2, _MMIOBitFieldRangeEnd>>

          public struct Raw: RegisterValueRaw {
            public typealias Value = S
            public typealias Storage = UInt8
            public var storage: Storage
            public init(_ storage: Storage) {
              self.storage = storage
            }
            public init(_ value: Value.Read) {
              self.storage = value.storage
            }
            public init(_ value: Value.Write) {
              self.storage = value.storage
            }
            public var v1: UInt8 {
              @inlinable @inline(__always) get {
                V1.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V1.insertBits(newValue, into: &self.storage)
              }
            }
            public var v2: UInt8 {
              @inlinable @inline(__always) get {
                V2.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insertBits(newValue, into: &self.storage)
              }
            }
          }

          public struct Read: RegisterValueRead {
            public typealias Value = S
            public var storage: UInt8
            public init(_ value: Raw) {
              self.storage = value.storage
            }
            public var v1: Bool {
              @inlinable @inline(__always) get {
                V1.extract(from: self.storage)
              }
            }
          }

          public struct Write: RegisterValueWrite {
            public typealias Value = S
            public var storage: UInt8
            public init(_ value: Raw) {
              self.storage = value.storage
            }
            public init(_ value: Read) {
              // FIXME: mask off bits
              self.storage = value.storage
            }
            public var v2: Bool {
              @available(*, deprecated, message: "API misuse; read from write view returns the value to be written, not the value initially read.")
              @inlinable @inline(__always) get {
                V2.extract(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V2.insert(newValue, into: &self.storage)
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

  @Test func bitRangeWithBoundsOutOfValidRegisterRange_emitsDiagnostics() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @Reserved(bits: 3..<10)
        var v: V
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var v: V {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          typealias V = _MMIOBitField<Self, UInt8, Never, _MMIOBitFieldRange<3, 8, _MMIOBitFieldRangeEnd>>

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
            var v: UInt8 {
              @inlinable @inline(__always) get {
                V.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V.insertBits(newValue, into: &self.storage)
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
      diagnostics: [
        .init(
          message: ErrorDiagnostic.bitFieldOutOfBounds(
            attribute: "@Reserved(bits: 3..<10)",
            pluralize: false
          ).message,
          line: 3,
          column: 4,
          highlights: ["Reserved"],
          notes: [
            .init(
              message:
                "bit range '3..<10' extends outside register bit range '0..<8'",
              line: 3,
              column: 19)
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func singleBitOutOfValidRegisterRange_emitsDiagnostics() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @Reserved(bits: 10)
        var v: V
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var v: V {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          typealias V = _MMIOBitField<Self, UInt8, Never, _MMIOBitFieldRange<7, 8, _MMIOBitFieldRangeEnd>>

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
            var v: UInt8 {
              @inlinable @inline(__always) get {
                V.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V.insertBits(newValue, into: &self.storage)
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
      diagnostics: [
        .init(
          message: ErrorDiagnostic.bitFieldOutOfBounds(
            attribute: "@Reserved(bits: 10)",
            pluralize: false
          ).message,
          line: 3,
          column: 4,
          highlights: ["Reserved"],
          notes: [
            .init(
              message:
                "bit range '10' extends outside register bit range '0..<8'",
              line: 3,
              column: 19)
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func negativeRangeBound_emitsDiagnostics() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @Reserved(bits: -1..<1)
        var v: V
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var v: V {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          typealias V = _MMIOBitField<Self, UInt8, Never, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRangeEnd>>

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
            var v: UInt8 {
              @inlinable @inline(__always) get {
                V.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V.insertBits(newValue, into: &self.storage)
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
      diagnostics: [
        .init(
          message: ErrorDiagnostic.bitFieldOutOfBounds(
            attribute: "@Reserved(bits: -1..<1)",
            pluralize: false
          ).message,
          line: 3,
          column: 4,
          highlights: ["Reserved"],
          notes: [
            .init(
              message:
                "bit range '-1..<1' extends outside register bit range '0..<8'",
              line: 3,
              column: 19)
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func negativeBitIndex_emitsDiagnostics() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 0x8)
      struct S {
        @Reserved(bits: -1)
        var v: V
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var v: V {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          typealias V = _MMIOBitField<Self, UInt8, Never, _MMIOBitFieldRange<0, 1, _MMIOBitFieldRangeEnd>>

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
            var v: UInt8 {
              @inlinable @inline(__always) get {
                V.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                V.insertBits(newValue, into: &self.storage)
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
      diagnostics: [
        .init(
          message: ErrorDiagnostic.bitFieldOutOfBounds(
            attribute: "@Reserved(bits: -1)",
            pluralize: false
          ).message,
          line: 3,
          column: 4,
          highlights: ["Reserved"],
          notes: [
            .init(
              message:
                "bit range '-1' extends outside register bit range '0..<8'",
              line: 3,
              column: 19)
          ])
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bitFieldWithOverlappingBitRanges_emitsDiagnostics() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 64)
      struct S {
        @Reserved(bits: 0..<24, 8..<32, 16..<48, 36..<44)
        var field: Field
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var field: Field {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          typealias Field = _MMIOBitField<Self, UInt64, Never, _MMIOBitFieldRange<0, 24, _MMIOBitFieldRange<8, 32, _MMIOBitFieldRange<16, 48, _MMIOBitFieldRange<36, 44, _MMIOBitFieldRangeEnd>>>>>

          struct Raw: RegisterValueRaw {
            typealias Value = S
            typealias Storage = UInt64
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var field: UInt64 {
              @inlinable @inline(__always) get {
                Field.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Field.insertBits(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = S
            var storage: UInt64
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
      diagnostics: [
        .init(
          message: ErrorDiagnostic.bitFieldOverlappingBitRanges(
            attribute: "@Reserved(bits: 0..<24, 8..<32, 16..<48, 36..<44)"
          )
          .message,
          line: 3,
          column: 4,
          highlights: ["Reserved"],
          notes: [
            .init(
              message:
                "bit range '0..<24' overlaps bit ranges '8..<32' and '16..<48' over subrange '8..<24'",
              line: 3,
              column: 19),
            .init(
              message:
                "bit range '8..<32' overlaps bit ranges '0..<24' and '16..<48'",
              line: 3,
              column: 27),
            .init(
              message:
                "bit range '16..<48' overlaps bit ranges '0..<24', '8..<32', and '36..<44' over subranges '16..<32' and '36..<44'",
              line: 3,
              column: 35),
            .init(
              message: "bit range '36..<44' overlaps bit range '16..<48'",
              line: 3,
              column: 44),
          ]
        )
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func bitFieldWithOverlappingIndexAndRange_emitsDiagnostics() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 8)
      struct S {
        @Reserved(bits: 2, 0..<4)
        var field: Field
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var field: Field {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          typealias Field = _MMIOBitField<Self, UInt8, Never, _MMIOBitFieldRange<2, 3, _MMIOBitFieldRange<0, 4, _MMIOBitFieldRangeEnd>>>

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
            var field: UInt8 {
              @inlinable @inline(__always) get {
                Field.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Field.insertBits(newValue, into: &self.storage)
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
      diagnostics: [
        .init(
          message: ErrorDiagnostic.bitFieldOverlappingBitRanges(
            attribute: "@Reserved(bits: 2, 0..<4)"
          )
          .message,
          line: 3,
          column: 4,
          highlights: ["Reserved"],
          notes: [
            .init(
              message:
                "bit range '0..<4' overlaps bit range '2' over subrange '2..<3'",
              line: 3,
              column: 22),
            .init(
              message: "bit range '2' overlaps bit range '0..<4'",
              line: 3,
              column: 19),
          ]
        )
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }

  @Test func registerWithOverlappingBitRanges_emitsDiagnostics() {
    assertMacroExpansion(
      """
      @Register(bitWidth: 64)
      struct S {
        @Reserved(bits: 0..<10)
        var field0: Field0

        @Reserved(bits: 0..<4, 8..<12)
        var field1: Field1

        @Reserved(bits: 10..<24)
        var field2: Field2

        @Reserved(bits: 23..<24)
        var field3: Field3
      }
      """,
      expandedSource: """
        struct S {
          @available(*, unavailable)
          var field0: Field0 {
            get {
              fatalError()
            }
          }
          @available(*, unavailable)
          var field1: Field1 {
            get {
              fatalError()
            }
          }
          @available(*, unavailable)
          var field2: Field2 {
            get {
              fatalError()
            }
          }
          @available(*, unavailable)
          var field3: Field3 {
            get {
              fatalError()
            }
          }

          private init() {
            fatalError()
          }

          private var _never: Never

          typealias Field0 = _MMIOBitField<Self, UInt64, Never, _MMIOBitFieldRange<0, 10, _MMIOBitFieldRangeEnd>>

          typealias Field1 = _MMIOBitField<Self, UInt64, Never, _MMIOBitFieldRange<0, 4, _MMIOBitFieldRange<8, 12, _MMIOBitFieldRangeEnd>>>

          typealias Field2 = _MMIOBitField<Self, UInt64, Never, _MMIOBitFieldRange<10, 24, _MMIOBitFieldRangeEnd>>

          typealias Field3 = _MMIOBitField<Self, UInt64, Never, _MMIOBitFieldRange<23, 24, _MMIOBitFieldRangeEnd>>

          struct Raw: RegisterValueRaw {
            typealias Value = S
            typealias Storage = UInt64
            var storage: Storage
            init(_ storage: Storage) {
              self.storage = storage
            }
            init(_ value: Value.ReadWrite) {
              self.storage = value.storage
            }
            var field0: UInt64 {
              @inlinable @inline(__always) get {
                Field0.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Field0.insertBits(newValue, into: &self.storage)
              }
            }
            var field1: UInt64 {
              @inlinable @inline(__always) get {
                Field1.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Field1.insertBits(newValue, into: &self.storage)
              }
            }
            var field2: UInt64 {
              @inlinable @inline(__always) get {
                Field2.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Field2.insertBits(newValue, into: &self.storage)
              }
            }
            var field3: UInt64 {
              @inlinable @inline(__always) get {
                Field3.extractBits(from: self.storage)
              }
              @inlinable @inline(__always) set {
                Field3.insertBits(newValue, into: &self.storage)
              }
            }
          }

          typealias Read = ReadWrite

          typealias Write = ReadWrite

          struct ReadWrite: RegisterValueRead, RegisterValueWrite {
            typealias Value = S
            var storage: UInt64
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
      diagnostics: [
        .init(
          message: ErrorDiagnostic.registerOverlappingBitRanges(name: "S")
            .message,
          line: 2,
          column: 8,
          highlights: ["S"],
          notes: [
            .init(
              message:
                "bit range '0..<4' overlaps bit range '0..<10' in 'field0'",
              line: 6,
              column: 19),
            .init(
              message:
                "bit range '0..<10' overlaps bit ranges '0..<4' and '8..<12' in 'field1'",
              line: 3,
              column: 19),
            .init(
              message:
                "bit range '8..<12' overlaps bit ranges '0..<10' in 'field0' and '10..<24' in 'field2'",
              line: 6,
              column: 26),
            .init(
              message:
                "bit range '10..<24' overlaps bit ranges '8..<12' in 'field1' and '23..<24' in 'field3'",
              line: 9,
              column: 19),
            .init(
              message:
                "bit range '23..<24' overlaps bit range '10..<24' in 'field2'",
              line: 12,
              column: 19),
          ]
        )
      ],
      macros: Self.macros,
      indentationWidth: Self.indentationWidth)
  }
}
#endif
