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
import SwiftSyntaxMacros

struct BitWidth {
  var value: Int
}

extension BitWidth: Equatable {}

extension BitWidth: ExpressibleByExprSyntax {
  init(
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    let value = try Int(expression: expression, in: context)
    let validBitWidths = [8, 16, 32, 64]
    guard validBitWidths.contains(value) else {
      throw context.error(
        at: expression,
        message: .expectedLiteralValue(in: validBitWidths))
    }
    self.value = value
  }
}

extension ErrorDiagnostic {
  static func expectedLiteralValue<T>(in values: [T]) -> Self {
    precondition(values.count > 1)
    guard let last = values.last else { fatalError() }

    let optionsPrefix =
      values
      .dropLast()
      .map { "'\($0)'" }
      .joined(separator: ", ")
    let options = "\(optionsPrefix), or '\(last)'"

    return .init(
      "'\(Macro.signature)' requires expression to be one of \(options)")
  }
}
