//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct LLVMDiagnosticIntegerParser: ParserProtocol {
  typealias Output = Int

  func parse(_ input: inout Input) -> Output? {
    let original = input
    var value = 0
    var digitsConsumed = false
    while !input.isEmpty {
      guard let digit = DecimalDigitParser().parse(&input) else { break }
      guard value.incrementalParseAppend(digit: Int(digit), base: 10)
      else {
        input = original
        return nil
      }
      digitsConsumed = true
    }
    guard digitsConsumed else {
      input = original
      return nil
    }
    return value
  }
}

struct LLVMDiagnosticKindParser: ParserProtocol {
  typealias Output = LLVMDiagnosticKind

  var parser = OneOfParser<Output>()

  func parse(_ input: inout Input) -> Output? {
    self.parser.parse(&input)
  }
}

struct LLVMDiagnosticParser: ParserProtocol {
  typealias Output = LLVMDiagnostic

  var parser: some ParserProtocol<Output> = BaseParser()
    .take(CollectUpToParser(":")).skip(DropParser(":"))  // file
    .take(LLVMDiagnosticIntegerParser()).skip(DropParser(":"))  // line
    .take(LLVMDiagnosticIntegerParser()).skip(DropParser(": "))  // column
    .take(LLVMDiagnosticKindParser()).skip(DropParser(": "))  // kind
    .take(CollectUpToParser("\n")).skip(DropParser("\n"))  // message
    .skip(CollectUpToParser("\n")).skip(DropParser("\n"))  // source line
    .skip(CollectUpToParser("\n"))  // highlight line
    .map {
      guard let file = String($0.0), let message = String($0.4) else {
        return nil
      }
      return LLVMDiagnostic(
        file: file,
        line: $0.1,
        column: $0.2,
        kind: $0.3,
        message: message)
    }

  func parse(_ input: inout Input) -> Output? {
    self.parser.parse(&input)
  }
}

public struct LLVMDiagnosticsParser: ParserProtocol {
  public typealias Output = [LLVMDiagnostic]

  var parser = ZeroOrMoreParser(
    parser: LLVMDiagnosticParser(),
    separator: "\n")

  public init() {}

  public func parse(_ input: inout Input) -> Output? {
    self.parser.parse(&input)
  }
}
