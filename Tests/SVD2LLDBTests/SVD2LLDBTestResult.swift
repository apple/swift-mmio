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

@testable import SVD2LLDB

struct SVD2LLDBTestResult {
  var output: String
  var warning: String
  var error: String

  init(output: String, warning: String, error: String) {
    self.output = output
    self.warning = warning
    self.error = error
  }

  init() {
    self.output = ""
    self.warning = ""
    self.error = ""
  }
}

extension SVD2LLDBTestResult: CustomStringConvertible {
  var description: String {
    var description = ""
    if !self.output.isEmpty {
      description.append(self.output)
    }
    if !self.warning.isEmpty {
      if !description.isEmpty {
        description.append("\n")
      }
      description.append(self.warning)
    }
    if !self.error.isEmpty {
      if !description.isEmpty {
        description.append("\n")
      }
      description.append(self.error)
    }
    return description
  }
}

extension SVD2LLDBTestResult: SVD2LLDBResult {
  mutating func output(_ string: String) {
    if !self.output.isEmpty {
      self.output.append("\n")
    }
    if string != "\n" {
      self.output.append(string)
    }
  }

  mutating func warning(_ string: String) {
    if !self.warning.isEmpty {
      self.warning.append("\n")
    }
    self.warning.append("warning: ")
    self.warning.append(string)
  }

  mutating func error(_ string: String) {
    if !self.error.isEmpty {
      self.error.append("\n")
    }
    self.error.append("error: ")
    self.error.append(string)
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
func XCTAssertSVD2LLDBResult(
  result: SVD2LLDBTestResult,
  output: String,
  file: StaticString = #file,
  line: UInt = #line
) {
  // Exit early if the actual output matches the expected output.
  let actualOutput = result.description
  let expectedOutput = output
  guard actualOutput != expectedOutput else { return }

  XCTFail(
    diff(expected: expectedOutput, actual: actualOutput, noun: "result"),
    file: file,
    line: line)
}
