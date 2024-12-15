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
import Testing

@testable import SVD2LLDB

func assertCommand<Command: SVD2LLDBCommand>(
  command _: Command.Type = Command.self,
  arguments: [String],
  success: Bool,
  debugger expectedDebugger: String,
  result expectedResult: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  let context = SVD2LLDB(device: device)
  var debugger = SVD2LLDBTestDebugger()
  var result = SVD2LLDBTestResult()
  #expect(
    Command.run(
      arguments: arguments,
      debugger: &debugger,
      result: &result,
      context: context) == success,
    sourceLocation: sourceLocation)

  let actualDebugger = debugger.description
  if actualDebugger != expectedDebugger {
    Issue.record(
      Comment(
        rawValue: diff(
          expected: expectedDebugger, actual: actualDebugger,
          noun: "debugger IO")),
      sourceLocation: sourceLocation)
  }

  let actualResult = result.description
  if actualResult != expectedResult {
    Issue.record(
      Comment(
        rawValue: diff(
          expected: expectedResult, actual: actualResult, noun: "result")),
      sourceLocation: sourceLocation)
  }
}
