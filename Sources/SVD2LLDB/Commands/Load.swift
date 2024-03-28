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

import CLLDB
import Foundation
import SVD

extension SVD2LLDB {
  static let loadName: StaticString = "load"
  static let loadHelp: StaticString = "load an svd file from disk"
  static let loadSyntax: StaticString = "load <svd-file-path>"
  func load(
    debugger: inout lldb.SBDebugger,
    arguments: [String],
    result: inout lldb.SBCommandReturnObject
  ) -> Bool {
    guard arguments.count == 1 else {
      // Report a usage error to the user.
      result.SetError("Usage: \(Self.loadSyntax)")
      // Return failure.
      return false
    }

    do {
      // Convert the argument to a url.
      let url = URL(fileURLWithPath: arguments[0])
      // Load input file from disk.
      let data = try Data(contentsOf: url)
      // Decode raw data into SVD types and save into plugin memory.
      self.device = try SVDDevice(svdData: data)
      // Report success to the user.
      result.Print("Loaded file “\(url.path)”.")
      // Return success.
      return true
    } catch {
      // Report the error to the user.
      result.SetError("\(error.localizedDescription)")
      // Return failure.
      return false
    }
  }
}
