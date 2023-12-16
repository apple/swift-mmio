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

import MMIOUtilities

extension Parser where Input == Substring, Output == Int {
  static let fileCheckDiagnosticInteger = Self { input in
    var match = 0
    var index = input.startIndex
    while index < input.endIndex {
      guard
        let ascii = input[index].asciiValue,
        UInt8(ascii: "0") <= ascii,
        ascii <= UInt8(ascii: "9")
      else { break }
      match = (match * 10) + Int(ascii - UInt8(ascii: "0"))
      input.formIndex(after: &index)
    }
    guard index != input.startIndex else { return nil }
    input = input[index...]
    return match
  }
}

extension Parser where Input == Substring, Output == FileCheckDiagnosticKind {
  static let fileCheckDiagnosticKind = Parser.cases()
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
      let element = Parser<Input, FileCheckDiagnostic>.fileCheckDiagnostic
      let separator = Parser<Input, Void>.dropPrefix("\n")
      guard let match = element.run(&input) else { return nil }

      var matches = [match]
      while true {
        let remaining = input
        guard
          separator.run(&input) != nil,
          let match = element.run(&input)
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
