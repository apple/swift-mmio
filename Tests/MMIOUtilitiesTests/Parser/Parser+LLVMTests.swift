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

import Testing

@testable import MMIOUtilities

extension ParserTests {
  struct LLVMParsingTestVector {
    static let vectors: [Self] = [
      Self(
        description: """
          /tests/TestModifyBitSetCoalesced.swift:56:17: error: CHECK-NEXT: expected string not found in input
          // CHECK-NEXT: %[[#REG+1]] = or i18 %[[#REG]], -127
                      ^
          """,
        diagnostic: LLVMDiagnostic(
          file: "/tests/TestModifyBitSetCoalesced.swift",
          line: 56,
          column: 17,
          kind: .error,
          message: "CHECK-NEXT: expected string not found in input")),
      Self(
        description: """
          /build/TestModifyBitSetCoalesced.swift.ll:2564:23: note: scanning from here
          %0 = load volatile i8, i8* inttoptr (i64 4096 to i8*), align 4096, !tbaa !19
                            ^
          """,
        diagnostic: LLVMDiagnostic(
          file: "/build/TestModifyBitSetCoalesced.swift.ll",
          line: 2564,
          column: 23,
          kind: .note,
          message: "scanning from here")),
      Self(
        description: """
          /build/TestModifyBitSetCoalesced.swift.ll:2564:23: note: with "REG+1" equal to "1"
          %0 = load volatile i8, i8* inttoptr (i64 4096 to i8*), align 4096, !tbaa !19
                            ^
          """,
        diagnostic: LLVMDiagnostic(
          file: "/build/TestModifyBitSetCoalesced.swift.ll",
          line: 2564,
          column: 23,
          kind: .note,
          message: #"with "REG+1" equal to "1""#)),
      Self(
        description: """
          /build/TestModifyBitSetCoalesced.swift.ll:2564:23: note: with "REG" equal to "0"
          %0 = load volatile i8, i8* inttoptr (i64 4096 to i8*), align 4096, !tbaa !19
                            ^
          """,
        diagnostic: LLVMDiagnostic(
          file: "/build/TestModifyBitSetCoalesced.swift.ll",
          line: 2564,
          column: 23,
          kind: .note,
          message: #"with "REG" equal to "0""#)),
      Self(
        description: """
          /build/TestModifyBitSetCoalesced.swift.ll:2565:3: note: possible intended match here
          %1 = or i8 %0, -127
          ^
          """,
        diagnostic: LLVMDiagnostic(
          file: "/build/TestModifyBitSetCoalesced.swift.ll",
          line: 2565,
          column: 3,
          kind: .note,
          message: "possible intended match here")),
      Self(
        description: """
          /build/TestModifyBitSetCoalesced.swift:21:10: warning: cannot find 'resister' in scope
          let r8 = resister<R8>(unsafeAddress: 0x1000)
              ~~   ^~~~~~~~
          """,
        diagnostic: LLVMDiagnostic(
          file: "/build/TestModifyBitSetCoalesced.swift",
          line: 21,
          column: 10,
          kind: .warning,
          message: "cannot find 'resister' in scope")),
    ]

    var description: String
    var diagnostic: LLVMDiagnostic
  }

  @Test(arguments: LLVMParsingTestVector.vectors)
  func parseLLVMDiagnostic(vector: LLVMParsingTestVector) throws {
    let actual = LLVMDiagnosticParser().parseAll(vector.description)
    let unwrapped = try #require(actual)
    #expect(unwrapped == vector.diagnostic)
  }
}
