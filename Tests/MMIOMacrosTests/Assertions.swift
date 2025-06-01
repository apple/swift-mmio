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

#if canImport(MMIOMacros)
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacros
import Testing

@testable import MMIOMacros

typealias SendableMacro = Macro & Sendable

func assertParse<Value>(
  expression: ExprSyntax,
  expected: Value,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) where Value: ExpressibleByExprSyntax, Value: Equatable {
  #expect(throws: Never.self, sourceLocation: sourceLocation) {
    let context = MacroContext.makeSuppressingDiagnostics(Macro0.self)
    let actual = try Value(expression: expression, in: context)
    #expect(actual == expected, sourceLocation: sourceLocation)
  }
}

func assertParseBitFieldTypeProjection(
  expression: ExprSyntax,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
  // swift-format-ignore: NeverForceUnwrap
  let base = expression.as(MemberAccessExprSyntax.self)!.base!
  assertParse(
    expression: expression,
    expected: BitFieldTypeProjection(expression: base),
    sourceLocation: sourceLocation)
}

func assertNoParse<Value>(
  expression: ExprSyntax,
  as _: Value.Type,
  sourceLocation: Testing.SourceLocation = #_sourceLocation
) where Value: ExpressibleByExprSyntax {
  #expect(throws: ExpansionError.self, sourceLocation: sourceLocation) {
    let context = MacroContext.makeSuppressingDiagnostics(Macro0.self)
    _ = try Value(expression: expression, in: context)
  }
}

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
#endif
