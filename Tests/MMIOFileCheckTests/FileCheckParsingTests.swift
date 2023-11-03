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

import XCTest

final class FileCheckParsingTests: XCTestCase {
  func testParseErrorOutput() {
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
      """

    let expected = [
      FileCheckDiagnostic(
        file: "/tests/TestModifyBitSetCoalesced.swift",
        line: 56,
        column: 17,
        kind: .error,
        message: "CHECK-NEXT: expected string not found in input"),
      FileCheckDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift.ll",
        line: 2564,
        column: 23,
        kind: .note,
        message: "scanning from here"),
      FileCheckDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift.ll",
        line: 2564,
        column: 23,
        kind: .note,
        message: #"with "REG+1" equal to "1""#),
      FileCheckDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift.ll",
        line: 2564,
        column: 23,
        kind: .note,
        message: #"with "REG" equal to "0""#),
      FileCheckDiagnostic(
        file: "/build/TestModifyBitSetCoalesced.swift.ll",
        line: 2565,
        column: 3,
        kind: .note,
        message: "possible intended match here"),
    ]

    var input = error[...]
    let (parsed, rest) = Parser.fileCheckDiagnostics.parse(&input)
    let actual = parsed ?? []
    XCTAssertEqual(actual.count, expected.count)
    if actual.count == expected.count {
      for (actual, expected) in zip(actual, expected) {
        XCTAssertEqual(actual, expected)
      }
    }
    XCTAssert(rest.isEmpty)
  }
}
