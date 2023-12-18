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
  static let llvmDiagnosticInteger = Self { input in
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

extension Parser where Input == Substring, Output == LLVMDiagnosticKind {
  static let llvmDiagnosticKind = Parser.cases()
}

extension Parser where Input == Substring, Output == LLVMDiagnostic {
  static var llvmDiagnostic: Self {
    Parser<Substring, Substring>
      .take(.prefix(upTo: ":")).skip(":")  // file
      .take(.llvmDiagnosticInteger).skip(":")  // line
      .take(.llvmDiagnosticInteger).skip(": ")  // column
      .take(.llvmDiagnosticKind).skip(": ")  // kind
      .take(.prefix(upTo: "\n")).skip("\n")  // message
      .skip(.prefix(upTo: "\n")).skip("\n")  // source line
      .skip(.prefix(upTo: "\n"))  // highlight line
      .map { parsed in
        LLVMDiagnostic(
          file: String(parsed.0),
          line: parsed.1,
          column: parsed.2,
          kind: parsed.3,
          message: String(parsed.4))
      }
  }

  public static let llvmDiagnostics = Self
    .llvmDiagnostic.oneOrMore(separatedBy: "\n")
}
