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

extension Parser where Input == Substring, Output == Int {
  static let fileCheckDiagnosticInteger = Self { input in
    var match = 0
    var index = input.startIndex
    while index < input.endIndex {
      let character = input[index]
      guard
        let asciiValue = character.asciiValue,
        UInt8(ascii: "0") <= asciiValue,
        asciiValue <= UInt8(ascii: "9")
      else { break }
      match = (match * 10) + Int(asciiValue - UInt8(ascii: "0"))
      input.formIndex(after: &index)
    }
    guard index != input.startIndex else { return nil }
    input = input[index...]
    return match
  }
}

extension Parser where Input == Substring, Output == FileCheckDiagnosticKind {
  static let fileCheckDiagnosticKind = Self { input in
    if input.hasPrefix(FileCheckDiagnosticKind.error.rawValue) {
      input.removeFirst(FileCheckDiagnosticKind.error.rawValue.count)
      return .error
    }

    if input.hasPrefix(FileCheckDiagnosticKind.note.rawValue) {
      input.removeFirst(FileCheckDiagnosticKind.note.rawValue.count)
      return .note
    }

    return nil
  }
}

extension Parser where Input == Substring, Output == FileCheckDiagnostic {
  static var fileCheckDiagnostic: Self {
    Parser<Substring, Substring>
      .take(.prefix(upTo: ":")).skip(":")  // file
      .take(.fileCheckDiagnosticInteger).skip(":")  // line
      .take(.fileCheckDiagnosticInteger).skip(": ")  // column
      .take(.fileCheckDiagnosticKind).skip(": ")  // kind
      .take(.prefix(upTo: "\n")).skip("\n")  // message
      .skip(.prefix(upTo: "\n")).skip("\n")  // source line
      .skip(.prefix(upTo: "^")).skip("^")  // trailing carrot
      .map { parsed in
        FileCheckDiagnostic(
          file: String(parsed.0),
          line: parsed.1,
          column: parsed.2,
          kind: parsed.3,
          message: String(parsed.4))
      }
  }
}

extension Parser where Input == Substring, Output == [FileCheckDiagnostic] {
  static var fileCheckDiagnostics: Self {
    Self { input in
      let element = Parser<Substring, FileCheckDiagnostic>.fileCheckDiagnostic
      let separator = Parser<Substring, Void>.dropPrefix("\n")
      guard let match = element.parse(&input) else { return nil }

      var matches = [match]
      while true {
        let remaining = input
        guard
          separator.parse(&input) != nil,
          let match = element.parse(&input)
        else {
          input = remaining
          break
        }
        matches.append(match)
      }

      return matches
    }
  }
}
