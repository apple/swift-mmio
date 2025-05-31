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


extension Parser where Input == String.UTF8View.SubSequence, Output == LLVMDiagnostic {
  static var llvmDiagnostic: Self {
    fatalError()
//    Parser<Substring, Substring>
//      .take(.prefix(upTo: ":")).skip(":")  // file
//      .take(LLVMDiagnosticIntegerParser2.parser()).skip(":")  // line
//      .take(LLVMDiagnosticIntegerParser2.parser()).skip(": ")  // column
//      .take(LLVMDiagnosticKindParser2.parser()).skip(": ")  // kind
//      .take(.prefix(upTo: "\n")).skip(PrefixParser2<NewLine>.parser())  // message
//      .skip(PrefixUpToParser2<NewLine>.parser()).skip(PrefixParser2<NewLine>.parser())  // source line
//      .skip(PrefixUpToParser2<NewLine>.parser())  // highlight line
//      .map { parsed in
//        LLVMDiagnostic(
//          file: String(parsed.0),
//          line: parsed.1,
//          column: parsed.2,
//          kind: parsed.3,
//          message: String(parsed.4))
//      }
  }

  public static let llvmDiagnostics: Parser<String.UTF8View.SubSequence, [LLVMDiagnostic]>  = { fatalError() }()
//  Self.llvmDiagnostic.oneOrMore(separatedBy: "\n".utf8[...])
}
