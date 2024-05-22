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

import ArgumentParser
import Foundation
import SVD

struct LoadCommand: SVD2LLDBCommand {
  static let autoRepeat = ""
  static let configuration = CommandConfiguration(
    commandName: "load",
    _superCommandName: "svd",
    abstract: "Load an SVD file from disk.")

  @Argument(help: "Path to SVD file.")
  var path: String

  mutating func run(
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: SVD2LLDB
  ) throws -> Bool {
    // Convert the file path to a url.
    let url = URL(fileURLWithPath: self.path)
    // Load input file from disk.
    let data = try Data(contentsOf: url)
    // Decode raw data into SVD types and save into plugin memory.
    context.device = try SVDDevice(svdData: data)
    // Report success to the user.
    result.output("Loaded SVD file: “\(url.lastPathComponent)”.")
    // Return success.
    return true
  }
}
