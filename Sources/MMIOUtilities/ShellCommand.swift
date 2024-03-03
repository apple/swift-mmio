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

#if os(macOS)
import Dispatch
import Foundation

extension Data {
  func asUTF8String() -> String {
    let output = String(data: self, encoding: .utf8) ?? ""
    guard output.hasSuffix("\n") else {
      return output
    }
    let endIndex = output.index(before: output.endIndex)
    return String(output[..<endIndex])
  }
}

public struct ShellCommandError: Swift.Error {
  public var command: String
  public var exitCode: Int32
  public var outputData: Data
  public var errorData: Data

  public var output: String { self.outputData.asUTF8String() }
  public var error: String { self.errorData.asUTF8String() }
}

extension ShellCommandError: CustomStringConvertible {
  public var description: String {
    var description =
      "Command '\(self.command)' exited with code '\(self.exitCode)'"
    let error = self.error
    if error != "" {
      description.append(": \"\(error)\"")
    }
    return description
  }
}

extension ShellCommandError: LocalizedError {
  public var errorDescription: String? { self.description }
}

public func sh(
  _ command: String,
  at path: String? = nil
) throws -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/bin/sh")
  process.arguments = ["-ic", "export PATH=$PATH:~/bin; \(command)"]

  // drain standard output and error into in-memory data.
  let drainQueue = DispatchQueue(label: "sh-drain-queue")

  var outputData = Data()
  let outputPipe = Pipe()
  process.standardOutput = outputPipe
  outputPipe.fileHandleForReading.readabilityHandler = { handler in
    let data = handler.availableData
    drainQueue.async {
      outputData.append(data)
    }
  }

  var errorData = Data()
  let errorPipe = Pipe()
  process.standardError = errorPipe
  errorPipe.fileHandleForReading.readabilityHandler = { handler in
    drainQueue.async { [data = handler.availableData] in
      errorData.append(data)
    }
  }

  // Launch the process and wait for it to complete.
  print(command)
  fflush(stdout)
  try? process.run()
  process.waitUntilExit()

  outputPipe.fileHandleForReading.readabilityHandler = nil
  errorPipe.fileHandleForReading.readabilityHandler = nil

  // Wait for all queue items to complete before checking the process exit code.
  drainQueue.sync {}

  guard process.terminationStatus == 0 else {
    throw ShellCommandError(
      command: command,
      exitCode: process.terminationStatus,
      outputData: outputData,
      errorData: errorData)
  }

  return outputData.asUTF8String()
}
#endif
