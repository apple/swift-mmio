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

struct UnexpectedNilError: Error {
  let file: StaticString
  let line: UInt

  init(file: StaticString = #file, line: UInt = #line) {
    self.file = file
    self.line = line
  }
}

extension Optional {
  func unwrap(or error: Error? = nil) throws -> Wrapped {
    guard let self = self else { throw error ?? UnexpectedNilError() }
    return self
  }
}
