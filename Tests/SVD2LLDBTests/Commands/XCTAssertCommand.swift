//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import MMIOUtilities
import XCTest

@testable import SVD2LLDB

// swift-format-ignore: AlwaysUseLowerCamelCase
func XCTAssertCommand<Command: SVD2LLDBCommand>(
  command _: Command.Type = Command.self,
  arguments: [String],
  success: Bool,
  debugger expectedDebugger: String,
  result expectedResult: String,
  file: StaticString = #file,
  line: UInt = #line
) {
  let context = SVD2LLDB(device: device)
  var debugger = SVD2LLDBTestDebugger()
  var result = SVD2LLDBTestResult()
  XCTAssertEqual(
    Command.run(
      arguments: arguments,
      debugger: &debugger,
      result: &result,
      context: context),
    success,
    file: file,
    line: line)

  let actualDebugger = debugger.description
  if actualDebugger != expectedDebugger {
    XCTFail(
      diff(
        expected: expectedDebugger,
        actual: actualDebugger,
        noun: "debugger IO"),
      file: file,
      line: line)
  }

  let actualResult = result.description
  if actualResult != expectedResult {
    XCTFail(
      diff(expected: expectedResult, actual: actualResult, noun: "result"),
      file: file,
      line: line)
  }
}
