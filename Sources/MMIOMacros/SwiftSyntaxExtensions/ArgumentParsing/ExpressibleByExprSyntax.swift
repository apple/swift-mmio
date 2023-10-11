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
    argument: ExprSyntax,
    label: String,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws
}

extension Int: ExpressibleByExprSyntax {
  init(
    argument: SwiftSyntax.ExprSyntax,
    label: String,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    guard
      let intLiteral = argument.as(IntegerLiteralExprSyntax.self),
      let int = intLiteral.value
    else {
      context.error(
        at: argument,
        message: .argumentMustIntegerLiteral(label: label))
      throw ExpansionError()
    }
    self = int
  }
}

extension Range<Int>: ExpressibleByExprSyntax {
  init(
    argument: ExprSyntax,
    label: String,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    let value: Self?
    if let infix = argument.as(InfixOperatorExprSyntax.self) {
      value = Self.make(infix: infix)
    } else if let sequence = argument.as(SequenceExprSyntax.self) {
      value = Self.make(sequence: sequence)
    } else {
      value = nil
    }
    guard let value = value else {
      context.error(
        at: argument,
        message: .argumentMustIntegerRangeLiteral(label: label))
      throw ExpansionError()
    }
    self = value
  }

  private static func make(infix: InfixOperatorExprSyntax) -> Self? {
    guard
      let left = infix.leftOperand.as(IntegerLiteralExprSyntax.self)?.value,
      let right = infix.rightOperand.as(IntegerLiteralExprSyntax.self)?.value,
      left < right,
      let op = infix.operator.as(BinaryOperatorExprSyntax.self),
      op.operator.text == "..<"
    else {
      return nil
    }
    return Self(uncheckedBounds: (left, right))
  }

  private static func make(sequence: SequenceExprSyntax) -> Self? {
    let elements = sequence.elements
    guard elements.count == 3 else { return nil }

    let index0 = elements.startIndex
    let index1 = elements.index(after: index0)
    let index2 = elements.index(after: index1)
    guard
      let left = elements[index0].as(IntegerLiteralExprSyntax.self)?.value,
      let right = elements[index2].as(IntegerLiteralExprSyntax.self)?.value,
      left < right,
      let op = elements[index1].as(BinaryOperatorExprSyntax.self),
      op.operator.text == "..<"
    else { return nil }
    return Self(uncheckedBounds: (left, right))
  }
}
