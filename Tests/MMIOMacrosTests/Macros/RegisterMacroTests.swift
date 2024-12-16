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

struct RegisterMacroTests {
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
            .init(message: "Insert '@Reserved(bits:)' macro"),
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
            .init(message: "Insert '@Reserved(bits:)' macro"),
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
            .init(message: "Insert '@Reserved(bits:)' macro"),
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

          enum V1: ContiguousBitField {
            typealias Storage = UInt8
            typealias Projection = Never
            static let bitRange = 0 ..< 1
          }

          enum V2: ContiguousBitField {
            typealias Storage = UInt8
            typealias Projection = Never
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

          enum V1: ContiguousBitField {
            typealias Storage = UInt8
            typealias Projection = Bool
            static let bitRange = 0 ..< 1
          }

          enum V2: ContiguousBitField {
            typealias Storage = UInt8
            typealias Projection = Never
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

          enum V1: DiscontiguousBitField {
            typealias Storage = UInt8
            typealias Projection = UInt16
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

          enum V1: ContiguousBitField {
            typealias Storage = UInt8
            typealias Projection = Bool
            static let bitRange = 0 ..< 1
          }

          enum V2: ContiguousBitField {
            typealias Storage = UInt8
            typealias Projection = Bool
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

          enum Unbounded: ContiguousBitField {
            typealias Storage = UInt32
            typealias Projection = Never
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

          enum PartialThrough: ContiguousBitField {
            typealias Storage = UInt32
            typealias Projection = Never
            static let bitRange = 0 ..< 17
          }

          enum PartialFrom: ContiguousBitField {
            typealias Storage = UInt32
            typealias Projection = Never
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

          enum PartialUpTo: ContiguousBitField {
            typealias Storage = UInt32
            typealias Projection = Never
            static let bitRange = 0 ..< 16
          }

          enum Closed: ContiguousBitField {
            typealias Storage = UInt32
            typealias Projection = Never
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

          public enum V1: ContiguousBitField {
            public typealias Storage = UInt8
            public typealias Projection = Bool
            public static let bitRange = 0 ..< 1
          }

          public enum V2: ContiguousBitField {
            public typealias Storage = UInt8
            public typealias Projection = Bool
            public static let bitRange = 1 ..< 2
          }

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
            var storage: UInt8
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
            var storage: UInt8
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

          enum V: ContiguousBitField {
            typealias Storage = UInt8
            typealias Projection = Never
            static let bitRange = 3 ..< 8
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

          enum Field: DiscontiguousBitField {
            typealias Storage = UInt64
            typealias Projection = Never
            static let bitRanges = [0 ..< 24, 8 ..< 32, 16 ..< 48, 36 ..< 44]
          }

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
}
#endif
