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

import MMIOUtilities
import XCTest

final class LLVMParsingTests: XCTestCase {
  func test_parse_errorOutput() {
    let error = """
      /tests/TestModifyBitSetCoalesced.swift:56:17: error: CHECK-NEXT: expected string not found in input
      // CHECK-NEXT: %[[#REG+1]] = or i18 %[[#REG]], -127
                  ^
      /build/TestModifyBitSetCoalesced.swift.ll:2564:23: note: scanning from here
      %0 = load volatile i8, i8* inttoptr (i64 4096 to i8*), align 4096, !tbaa !19
                        ^
      /build/TestModifyBitSetCoalesced.swift.ll:2564:23: note: with "REG+1" equal to "1"
      %0 = load volatile i8, i8* inttoptr (i64 4096 to i8*), align 4096, !tbaa !19
                        ^
      /build/TestModifyBitSetCoalesced.swift.ll:2564:23: note: with "REG" equal to "0"
      %0 = load volatile i8, i8* inttoptr (i64 4096 to i8*), align 4096, !tbaa !19
                        ^
      /build/TestModifyBitSetCoalesced.swift.ll:2565:3: note: possible intended match here
      %1 = or i8 %0, -127
      ^
      /build/TestModifyBitSetCoalesced.swift:21:10: warning: cannot find 'resister' in scope
      let r8 = resister<R8>(unsafeAddress: 0x1000)
          ~~   ^~~~~~~~
      """

    let expected = [
      LLVMDiagnostic(
        file: "/tests/TestModifyBitSetCoalesced.swift",
        line: 56,
        column: 17,
        kind: .error,
        message: "CHECK-NEXT: expected string not found in input"),
      LLVMDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift.ll",
        line: 2564,
        column: 23,
        kind: .note,
        message: "scanning from here"),
      LLVMDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift.ll",
        line: 2564,
        column: 23,
        kind: .note,
        message: #"with "REG+1" equal to "1""#),
      LLVMDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift.ll",
        line: 2564,
        column: 23,
        kind: .note,
        message: #"with "REG" equal to "0""#),
      LLVMDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift.ll",
        line: 2565,
        column: 3,
        kind: .note,
        message: "possible intended match here"),
      LLVMDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift",
        line: 21,
        column: 10,
        kind: .warning,
        message: "cannot find 'resister' in scope"),
    ]

    var input = error[...]
    let parsed = Parser.llvmDiagnostics.run(&input)
    let actual = parsed ?? []
    XCTAssertEqual(actual.count, expected.count)
    if actual.count == expected.count {
      for (actual, expected) in zip(actual, expected) {
        XCTAssertEqual(actual, expected)
      }
    }
    XCTAssert(input.isEmpty)
  }
}
