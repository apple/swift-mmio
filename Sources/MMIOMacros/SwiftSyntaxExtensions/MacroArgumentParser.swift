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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum MacroArgumentParser {
  // Does not support variadic arguments, omitted labels should be passed as "_"
  static func parse(
    macro: String,
    labels: [String],
    node: AttributeSyntax,
    context: some MacroExpansionContext
  ) -> [ExprSyntax]? {
    var parsedArguments = [ExprSyntax]()
    let arguments = node.arguments?.as(LabeledExprListSyntax.self)
    let argumentCount = arguments?.count ?? 0
    guard labels.count == argumentCount else {
      context.diagnose(
        .init(
          node: Syntax(node.arguments) ?? Syntax(node),
          message: Diagnostics.Errors.incorrectCount(
            macro: macro,
            expected: labels.count,
            actual: argumentCount)))
      return nil
    }

    guard let arguments = arguments else { return parsedArguments }

    for (index, (expectedLabel, argument)) in zip(labels, arguments).enumerated() {
      let actualLabel = argument.label?.text ?? "_"
      guard actualLabel == expectedLabel else {
        context.diagnose(
          .init(
            node: Syntax(argument.label) ?? Syntax(argument),
            message: Diagnostics.Errors.incorrectLabel(
              macro: macro,
              index: index,
              expected: expectedLabel,
              actual: actualLabel)))
        return nil
      }
      parsedArguments.append(argument.expression)
    }

    return parsedArguments
  }
}

extension MacroArgumentParser {
  enum Diagnostics {
    struct Errors: DiagnosticMessage {
      static var suffix = """
        Please file an issue at \
        https://github.com/apple/swift-mmio/issues and, if possible, attach \
        the source code that triggered the issue
        """
      var id: StaticString
      var diagnosticID: MessageID {
        .init(domain: "\(MacroArgumentParser.self)", id: "\(self.id)")
      }
      var severity: DiagnosticSeverity
      var message: String

      init(
        message: String,
        severity: DiagnosticSeverity = .error,
        id: StaticString = #function
      ) {
        self.id = id
        self.severity = severity
        self.message = message
      }

      static func incorrectCount(
        macro: String, expected: Int, actual: Int
      ) -> Self {
        self.init(
          message: """
            '\(macro)' internal error. Incorrect number of macro arguments, \
            expected '\(expected)' received '\(actual)'. \(Self.suffix)
            """)
      }

      static func incorrectLabel(
        macro: String, index: Int, expected: String, actual: String
      ) -> Self {
        self.init(
          message: """
            '\(macro)' internal error. Incorrect label for macro argument \
            \(index), expected '\(expected)' received '\(actual)'. \
            \(Self.suffix)
            """)
      }
    }
  }
}
