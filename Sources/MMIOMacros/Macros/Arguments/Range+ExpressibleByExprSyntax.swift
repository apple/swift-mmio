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

extension Range: ExpressibleByExprSyntax where Bound: ExpressibleByExprSyntax {
  init(
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    if let infix = expression.as(InfixOperatorExprSyntax.self) {
      self = try Self.make(
        overall: infix,
        left: infix.leftOperand,
        op: infix.operator,
        right: infix.rightOperand,
        in: context)
    } else if let sequence = expression.as(SequenceExprSyntax.self) {
      let elements = sequence.elements
      guard elements.count == 3 else {
        throw context.error(
          at: sequence,
          message: .expectedRangeLiteral())
      }

      let index0 = elements.startIndex
      let index1 = elements.index(after: index0)
      let index2 = elements.index(after: index1)

      self = try Self.make(
        overall: sequence,
        left: elements[index0],
        op: elements[index1],
        right: elements[index2],
        in: context)
    } else {
      throw context.error(
        at: expression,
        message: .expectedRangeLiteral())
    }
  }

  private static func make(
    overall: some ExprSyntaxProtocol,
    left: ExprSyntax,
    op: ExprSyntax,
    right: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> Self {
    guard
      let op = op.as(BinaryOperatorExprSyntax.self),
      op.operator.text == "..<"
    else {
      throw context.error(
        at: overall,
        message: .expectedRangeLiteral())
    }

    let left = try Bound(expression: left, in: context)
    let right = try Bound(expression: right, in: context)
    guard left < right else {
      throw context.error(
        at: overall,
        message: .expectedRangeLiteral())
    }
    return Self(uncheckedBounds: (left, right))
  }
}

extension ErrorDiagnostic {
  static func expectedRangeLiteral() -> Self {
    .init("'\(Macro.signature)' requires expression to be a range literal")
  }
}
