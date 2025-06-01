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
import MMIOUtilities

/// A minimal implementation of LLVM's FileCheck with no configurability.
///
/// SimpleFileCheck is not intended for general use.
struct SimpleFileCheck {
  var inputFile: URL
  var outputFile: URL
}

extension SimpleFileCheck {
  func run() -> [LLVMDiagnostic] {
    // Load the input file and split it into lines. If we can't load the file,
    // return and report diagnostics.
    let inputPath = self.inputFile.path
    let input: String
    do {
      input = try String(contentsOf: self.inputFile, encoding: .utf8)
    } catch {
      return [.failedToLoadFile(at: inputPath, error: error)]
    }
    let inputLines = input.split(
      separator: "\n", omittingEmptySubsequences: false)
    var currentInputIndex = inputLines.startIndex

    // Load the output file and split it into lines. If we can't load the file,
    // return and report diagnostics.
    let outputPath = self.outputFile.path
    let output: String
    do {
      output = try String(contentsOf: self.outputFile, encoding: .utf8)
    } catch {
      return [.failedToLoadFile(at: outputPath, error: error)]
    }
    let outputLines = output.split(
      separator: "\n", omittingEmptySubsequences: false)
    var currentOutputIndex = outputLines.startIndex

    // Iterate through the input file looking for file check directives.
    while currentInputIndex < inputLines.endIndex {
      // Get the current line in the input file.
      let currentInputLine = inputLines[currentInputIndex]
      // Increment the position in the input file before starting the next loop
      // iteration.
      defer { inputLines.formIndex(after: &currentInputIndex) }

      // Parse the current input line into a file check directive, continuing
      // onto the next line if no directive is found.
      let directive = FileCheckDirective(input: currentInputLine)
      guard let directive = directive else { continue }

      // Record the current position in the input file so we can report a
      // diagnostic at the proper line if no match is found.
      let currentInputLineNumber =
        inputLines.distance(
          from: inputLines.startIndex,
          to: currentInputIndex)

      // Record the current position in the output file so we can report a
      // diagnostic noting where checking started from.
      let currentOutputLineNumber =
        outputLines.distance(
          from: outputLines.startIndex,
          to: currentOutputIndex)

      func matchNotFound() -> [LLVMDiagnostic] {
        [
          .init(
            file: inputPath,
            line: currentInputLineNumber + 1,
            column: directive.column,
            kind: .error,
            message: "Failed to match directive '\(directive.match)'"),
          .init(
            file: outputPath,
            line: currentOutputLineNumber + 1,
            column: 1,
            kind: .note,
            message: "Started searching for matches here"),
        ]
      }

      // Note this implementation is unable to match content on the very first
      // output line.
      switch directive.kind {
      case .plain, .label:
        // Increment the position in the output file.
        outputLines.formIndex(after: &currentOutputIndex)

        // Iterate through the output file looking for line matching the
        // directive.
        while currentOutputIndex < outputLines.endIndex {
          // Get the current line in the output file.
          let currentOutputLine = outputLines[currentOutputIndex]

          // Exit this loop if the output file line matches the directive.
          if currentOutputLine.contains(directive.match) { break }

          // Increment the position in the output file.
          outputLines.formIndex(after: &currentOutputIndex)
        }

        // If the loop above exited because it exhausted the output file
        // lines, then return and report diagnostics.
        if currentOutputIndex == outputLines.endIndex {
          return matchNotFound()
        }

      case .next:
        // Increment the position in the output file.
        outputLines.formIndex(after: &currentOutputIndex)

        // Check that the current output file line matches the directive.
        guard
          currentOutputIndex < outputLines.endIndex,
          case let currentOutputLine = outputLines[currentOutputIndex],
          currentOutputLine.contains(directive.match)
        else {
          return matchNotFound()
        }

      case .same:
        // Check that the current output file line matches the directive.
        guard
          currentOutputIndex < outputLines.endIndex,
          case let currentOutputLine = outputLines[currentOutputIndex],
          currentOutputLine.contains(directive.match)
        else {
          return matchNotFound()
        }
      }
    }

    return []
  }
}

extension LLVMDiagnostic {
  static func failedToLoadFile(at path: String, error: any Error) -> Self {
    .init(file: path, line: 1, column: 1, kind: .error, message: "\(error)")
  }
}
