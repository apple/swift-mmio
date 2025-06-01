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
  case inMemory([String: String])
}

struct OutputWriter {
  struct Scope {
    static let root = Self(
      name: "<root>",
      headerInserted: true,
      contentInserted: false)

    var name: String
    var headerInserted: Bool
    var contentInserted: Bool
  }

  var output: Output
  var indentation: Indentation
  var indentationLevel: Int
  var fileContent: String
  var scopes: [Scope]
}

extension OutputWriter {
  init(output: Output, indentation: Indentation) {
    self.output = output
    self.indentation = indentation
    self.indentationLevel = 0
    self.fileContent = ""
    self.scopes = [.root]
  }
}

extension OutputWriter {
  var parentScope: Scope? {
    self.scopes.last
  }

  var currentScope: Scope {
    _read {
      guard let scope = self.scopes.last else {
        preconditionFailure("No scope")
      }
      yield scope
    }
    _modify {
      guard var scope = self.scopes.last else {
        preconditionFailure("No scope")
      }
      yield &scope
      self.scopes[self.scopes.count - 1] = scope
    }
  }

  mutating func pushScope(_ scope: Scope) {
    self.scopes.append(scope)
  }

  mutating func popScope() -> Scope {
    self.scopes.removeLast()
  }

  mutating func scope<T, E>(
    _ name: String,
    lazy: Bool = false,
    body: (inout Self) throws(E) -> T
  ) throws(E) -> T where E: Error {
    guard !name.isEmpty else { return try body(&self) }

    let scope = Scope(
      name: name,
      headerInserted: !lazy,
      contentInserted: false)

    if !lazy {
      self.insert("\(scope.name) {")
      self.indentationLevel += 1
    }

    self.pushScope(scope)
    let returnValue = try body(&self)
    let currentScope = self.popScope()

    if currentScope.headerInserted {
      self.indentationLevel -= 1
      self.write("}\n")
    }

    return returnValue
  }

  mutating func insert(_ fileContent: String) {
    var parentScope: Scope?
    for index in self.scopes.indices {
      var scope = self.scopes[index]

      if !scope.headerInserted {
        if parentScope?.contentInserted == true {
          self.write("\n")
        }

        self.write("\(scope.name) {\n")
        self.indentationLevel += 1
        scope.headerInserted = true
      }

      parentScope = scope
      self.scopes[index] = scope
    }

    if self.currentScope.contentInserted {
      self.write("\n")
    }
    self.currentScope.contentInserted = true
    self.write(fileContent)
    self.write("\n")
  }
}

extension OutputWriter {
  mutating func write(_ fileContent: String) {
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

  mutating func flush(to path: String) throws {
    precondition(
      self.indentationLevel == 0,
      "Failed to fully unwind indentation, currently: \(self.indentationLevel)")
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
    case .inMemory(var dictionary):
      dictionary[path] = fileContent
      self.output = .inMemory(dictionary)
    }
    self.fileContent = ""
    self.scopes = [.root]
  }
}
