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
import SVD

protocol SVD2LLDBCommand: ParsableCommand {
  static var autoRepeat: String { get }

  mutating func run(
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: SVD2LLDB
  ) throws -> Bool
}

extension SVD2LLDBCommand {
  static func run(
    arguments: consuming [String],
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: SVD2LLDB
  ) -> Bool {
    do {
      var command = try Self.parse(arguments)
      return try command.run(
        debugger: &debugger,
        result: &result,
        context: context)
    } catch {
      let success = Self.exitCode(for: error).isSuccess
      let message = Self.message(for: error)
      if (error is ValidationError) || message.contains("argument") {
        result.output("usage: \(Self.usageString())")
      }
      if success {
        result.output(message)
      } else {
        result.error(message)
      }
      return success
    }
  }
}
