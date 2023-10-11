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

protocol ExpressibleByExprSyntax {
  init(
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws
}

extension ExprSyntax: ExpressibleByExprSyntax {
  init(
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    self = expression
  }
}

extension Int: ExpressibleByExprSyntax {
  init(
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    guard
      let intLiteral = expression.as(IntegerLiteralExprSyntax.self),
      let int = intLiteral.value
    else {
      context.error(
        at: expression,
        message: .expectedIntegerLiteral())
      throw ExpansionError()
    }
    self = int
  }
}

struct BitWidth: Equatable, ExpressibleByExprSyntax {
  var value: Int

  init(value: Int) {
    self.value = value
  }

  init(
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    let value = try Int(expression: expression, in: context)
    let validBitWidths = [8, 16, 32, 64]
    guard validBitWidths.contains(value) else {
      context.error(
        at: expression,
        message: .expectedIntegerLiteral(in: validBitWidths))
      throw ExpansionError()
    }
    self.value = value
  }
}

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
        context.error(
          at: sequence,
          message: .expectedRangeLiteral())
        throw ExpansionError()
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
      context.error(
        at: expression,
        message: .expectedRangeLiteral())
      throw ExpansionError()
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
      context.error(
        at: overall,
        message: .expectedRangeLiteral())
      throw ExpansionError()
    }

    let left = try Bound(expression: left, in: context)
    let right = try Bound(expression: right, in: context)
    guard left < right else {
      context.error(
        at: overall,
        message: .expectedRangeLiteral())
      throw ExpansionError()
    }
    return Self(uncheckedBounds: (left, right))
  }
}

extension ErrorDiagnostic {
  static func expectedIntegerLiteral() -> Self {
    .init("'\(Macro.signature)' requires expression to be an integer literal")
  }

  static func expectedIntegerLiteral(in values: [Int]) -> Self {
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

  static func expectedRangeLiteral() -> Self {
    .init("'\(Macro.signature)' requires expression to be a range literal")
  }
}
