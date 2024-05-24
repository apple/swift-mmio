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

import LLDB

extension lldb.SBError: CustomStringConvertible {
  @_documentation(visibility: internal)
  public var description: String {
    if self.IsValid(), let cString = lldb.GetCString(self) {
      String(cString: cString)
    } else {
      ""
    }
  }
}

extension lldb.SBError: Error {}
