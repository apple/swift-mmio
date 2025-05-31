//
//  LLVMDiagnosticInteger.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 5/30/25.
//

struct LLVMDiagnosticIntegerParser2: Parser2 {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = Int

  static func parse(_ input: inout Input) -> Output? {
    let digitParser2 = DecimalDigitParser2.self
    var match = 0
    var parsed = false
    while !input.isEmpty {
      guard
        let digit = digitParser2.parse(&input),
        match.incrementalParseAppend(digit: Int(digit), base: 10)
      else { break }
      parsed = true
    }
    guard parsed else { return nil }
    return match
  }
}

struct LLVMDiagnosticKindParser2: Parser2 {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = LLVMDiagnosticKind

  static func parse(_ input: inout Input) -> Output? {
    LLVMDiagnosticKind(rawValue: String(decoding: input, as: Unicode.UTF8.self).lowercased())
  }
}
