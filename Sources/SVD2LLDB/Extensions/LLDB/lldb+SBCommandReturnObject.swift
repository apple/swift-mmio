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

import CLLDB

extension lldb.SBCommandReturnObject: SVD2LLDBResult {
  mutating func output(_ string: String) {
    var string = string
    string.withUTF8 { buffer in
      self.PutCString(buffer.baseAddress, Int32(buffer.count))
    }
  }

  mutating func warning(_ string: String) {
    self.AppendWarning(string)
  }

  mutating func error(_ string: String) {
    self.SetError(string)
  }
}
