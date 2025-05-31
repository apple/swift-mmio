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

extension Parser2 {

}

struct LLVMDiagnosticIntegerParser2: ParserProtocol {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = Int

  func parse(_ input: inout Input) -> Output? {
    let digitParser2 = DecimalDigitParser2.self
    var match = 0
    var parsed = false
    while !input.isEmpty {
      guard
        let digit = Parser2.decimalDigit().parse(&input),
        match.incrementalParseAppend(digit: Int(digit), base: 10)
      else { break }
      parsed = true
    }
    guard parsed else { return nil }
    return match
  }
}

struct LLVMDiagnosticKindParser2: ParserProtocol {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = LLVMDiagnosticKind

  func parse(_ input: inout Input) -> Output? {
    LLVMDiagnosticKind(rawValue: String(decoding: input, as: Unicode.UTF8.self).lowercased())
  }
}
