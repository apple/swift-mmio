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
  collectStandardOutput: Bool = true,
  collectStandardError: Bool = true
) throws(ShellCommandError) -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/bin/sh")
  process.arguments = ["-c", "export PATH=$PATH:~/bin; \(command)"]

  let outputData = Mutex(Data())
  let outputPipe = Pipe()
  if collectStandardOutput {
    process.standardOutput = outputPipe
    outputPipe.fileHandleForReading.readabilityHandler = { handler in
      outputData.withLock { $0.append(handler.availableData) }
    }
  }

  let errorData = Mutex(Data())
  let errorPipe = Pipe()
  if collectStandardError {
    process.standardError = errorPipe
    errorPipe.fileHandleForReading.readabilityHandler = { handler in
      errorData.withLock { $0.append(handler.availableData) }
    }
  }

  // Launch the process and wait for it to complete.
  print(command)
  try? process.run()
  process.waitUntilExit()

  outputPipe.fileHandleForReading.readabilityHandler = nil
  errorPipe.fileHandleForReading.readabilityHandler = nil

  guard process.terminationStatus == 0 else {
    throw ShellCommandError(
      command: command,
      exitCode: process.terminationStatus,
      outputData: outputData.withLock { $0 },
      errorData: errorData.withLock { $0 })
  }

  return outputData.withLock { $0 }.asUTF8String()
}
