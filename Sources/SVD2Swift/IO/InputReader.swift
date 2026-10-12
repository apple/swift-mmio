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

import Foundation

enum Input {
  case standardInput
  case file(String)
}

struct InputReader {
  var input: Input

  func read() throws -> Data {
    switch self.input {
    case .standardInput:
      return try FileHandle.standardInput.readToEnd() ?? Data()
    case .file(let inputFile):
      let inputFileURL = URL(fileURLWithPath: inputFile)
      return try Data(contentsOf: inputFileURL)
    }
  }
}
