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

import SwiftSyntax
import SwiftSyntaxMacros

protocol ParsableMacroArguments {
  init(arguments: [ExprSyntax])
}

protocol ParsableMacro {
  associatedtype Arguments: ParsableMacroArguments

  static var baseName: String { get }
  static var labels: [String] { get }
}

extension ParsableMacro {
  static var labelSignature: String {
    guard !self.labels.isEmpty else { return "" }
    var signature = "("
    for label in self.labels {
      signature.append(label)
      signature.append(":")
    }
    signature.append(")")
    return signature
  }

  static var signature: String {
    "@\(self.baseName)\(self.labelSignature)"
  }

  // Does not support variadic arguments, omitted labels should be passed as "_"
  static func parse(
    from node: AttributeSyntax,
    in context: some MacroExpansionContext
  ) -> Arguments? {
    let diagnostics = DiagnosticBuilder<Self>()

    let arguments = node.arguments?.as(LabeledExprListSyntax.self)
    let argumentCount = arguments?.count ?? 0
    guard Self.labels.count == argumentCount else {
      context.diagnose(
        .init(
          node: Syntax(node.arguments) ?? Syntax(node),
          message: diagnostics.incorrectArgumentCount(
            expected: Self.labels.count,
            actual: argumentCount)))
      return nil
    }

    guard let arguments = arguments else { return nil }

    var parsedArguments = [ExprSyntax]()
    for (index, argument) in zip(Self.labels, arguments).enumerated() {
      let (expectedLabel, argument) = argument
      let actualLabel = argument.label?.text ?? "_"
      guard actualLabel == expectedLabel else {
        context.diagnose(
          .init(
            node: Syntax(argument.label) ?? Syntax(argument),
            message: diagnostics.incorrectArgumentLabel(
              index: index,
              expected: expectedLabel,
              actual: actualLabel)))
        return nil
      }
      parsedArguments.append(argument.expression)
    }

    return Arguments(arguments: parsedArguments)
  }
}
