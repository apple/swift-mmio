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

import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

typealias SendableMacro = Macro & Sendable

// Shim "assertMacroExpansion" to use swift-testing
typealias NoteSpec = SwiftSyntaxMacrosGenericTestSupport.NoteSpec
typealias FixItSpec = SwiftSyntaxMacrosGenericTestSupport.FixItSpec
typealias DiagnosticSpec = SwiftSyntaxMacrosGenericTestSupport.DiagnosticSpec

func assertMacroExpansion(
  _ originalSource: String,
  expandedSource expectedExpandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  macros: [String: Macro.Type],
  applyFixIts: [String]? = nil,
  fixedSource expectedFixedSource: String? = nil,
  testModuleName: String = "TestModule",
  testFileName: String = "test.swift",
  indentationWidth: Trivia = .spaces(4),
  sourceLocation: Testing.SourceLocation = #_sourceLocation,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath
) {
  SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
    originalSource,
    expandedSource: expectedExpandedSource,
    diagnostics: diagnostics,
    macroSpecs: macros.mapValues { MacroSpec(type: $0) },
    applyFixIts: applyFixIts,
    fixedSource: expectedFixedSource,
    testModuleName: testModuleName,
    testFileName: testFileName,
    indentationWidth: indentationWidth,
    failureHandler: {
      Issue.record(
        Comment(rawValue: $0.message),
        sourceLocation: .init(
          fileID: $0.location.fileID,
          filePath: $0.location.filePath,
          line: $0.location.line,
          column: $0.location.column))
    },
    fileID: fileID,
    filePath: filePath,
    line: UInt(sourceLocation.line),
    column: UInt(sourceLocation.column))
}
