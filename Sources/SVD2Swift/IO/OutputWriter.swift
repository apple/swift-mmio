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

enum Indentation {
  case tab
  case space(Int)
}

extension Indentation {
  var description: String {
    switch self {
    case .tab:
      "\t"
    case .space(let count):
      String(repeating: " ", count: count)
    }
  }
}

enum Output {
  case standardOutput
  case directory(String)
}

struct OutputWriter {
  var output: Output
  var indentation: Indentation
  var indentationLevel: Int
  var fileContent: String

  init(output: Output, indentation: Indentation) {
    self.output = output
    self.indentation = indentation
    self.indentationLevel = 0
    self.fileContent = ""
  }

  mutating func indent() {
    self.indentationLevel += 1
  }

  mutating func outdent() {
    self.indentationLevel -= 1
  }

  mutating func append(_ fileContent: String) {
    guard !fileContent.isEmpty else { return }
    let lines =
      fileContent
      .split(separator: "\n", omittingEmptySubsequences: false)

    var isFirst = true
    for line in lines {
      if isFirst {
        isFirst = false
      } else {
        self.fileContent.append(contentsOf: "\n")
      }
      if !line.isEmpty {
        for _ in 0..<self.indentationLevel {
          self.fileContent.append(contentsOf: self.indentation.description)
        }
        self.fileContent.append(contentsOf: line)
      }
    }
  }

  mutating func writeOutput(to path: String) throws {
    precondition(
      self.indentationLevel == 0,
      "Failed to fully unwind indentation")
    switch self.output {
    case .standardOutput:
      print(self.fileContent, terminator: "")
    case .directory(let outputDirectory):
      let outputDirectoryURL = URL(fileURLWithPath: outputDirectory)
      try FileManager.default.createDirectory(
        at: outputDirectoryURL,
        withIntermediateDirectories: true)
      let outputFileURL = outputDirectoryURL.appendingPathComponent(path)
      try self.fileContent
        .data(using: .utf8)?
        .write(to: outputFileURL)
    }
    self.fileContent = ""
  }
}
