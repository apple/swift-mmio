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
      if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
        return try FileHandle.standardInput.readToEnd() ?? Data()
      } else {
        // This can raise an ObjC exception which is not handleable in Swift. If
        // users see this occur then replace this code with a different cross
        // platform API, e.g. open(2) and read(2) on POSIX compatible platforms.
        return FileHandle.standardInput.readDataToEndOfFile()
      }
    case .file(let inputFile):
      let inputFileURL = URL(fileURLWithPath: inputFile)
      return try Data(contentsOf: inputFileURL)
    }
  }
}
