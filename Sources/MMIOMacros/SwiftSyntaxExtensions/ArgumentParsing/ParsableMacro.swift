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
  init(
    arguments: [ExprSyntax],
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws
}

protocol ParsableMacro {
  associatedtype Arguments: ParsableMacroArguments

  static var baseName: String { get }
  static var arguments: [(label: String, type: String)] { get }

  init(arguments: Arguments)
}

extension ParsableMacro {
  static var argumentSignature: String {
    guard !self.arguments.isEmpty else { return "" }
    var signature = "("
    for argument in self.arguments {
      signature.append(argument.label)
      signature.append(":")
    }
    signature.append(")")
    return signature
  }

  static var signature: String {
    "@\(self.baseName)\(self.argumentSignature)"
  }
}

extension ParsableMacro {
  static var argumentPlaceholder: String {
    guard !self.arguments.isEmpty else { return "" }
    var signature = "("
    for argument in self.arguments {
      signature.append(argument.label)
      signature.append(": ")
      signature.append("<#\(argument.type)#>")
    }
    signature.append(")")
    return signature
  }

  static var placeholder: AttributeListSyntax.Element {
    .attribute("@\(raw: self.baseName)\(raw: self.argumentPlaceholder)")
  }
}

extension ParsableMacro {
  // Does not support variadic arguments, omitted labels should be passed as "_"
  init(
    from node: AttributeSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    let expectedArguments = Self.arguments
    let actualArguments = node.arguments?.as(LabeledExprListSyntax.self)
    let expectedArgumentCount = Self.arguments.count
    let actualArgumentCount = actualArguments?.count ?? 0
    guard expectedArgumentCount == actualArgumentCount else {
      context.error(
        at: Syntax(node.arguments) ?? Syntax(node),
        message: .incorrectArgumentCount(
          expected: expectedArgumentCount,
          actual: actualArgumentCount))
      throw ExpansionError()
    }

    var parsedArguments = [ExprSyntax]()

    if let actualArguments = actualArguments {
      let arguments = zip(expectedArguments, actualArguments)
      for (index, (expected, actual)) in arguments.enumerated() {
        let expectedLabel = expected.label
        let actualLabel = actual.label?.text ?? "_"
        guard actualLabel == expectedLabel else {
          context.error(
            at: Syntax(actual.label) ?? Syntax(actual),
            message: .incorrectArgumentLabel(
              index: index,
              expected: expectedLabel,
              actual: actualLabel))
          throw ExpansionError()
        }
        parsedArguments.append(actual.expression)
      }
    }

    try self.init(arguments: Arguments(arguments: parsedArguments, in: context))
  }
}
