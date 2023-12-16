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

import MMIOUtilities
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxMacros

struct BitRangeBound: Equatable {
  var value: Int
  var inclusive: Bool
}

struct BitRange {
  var lowerBound: BitRangeBound?
  var upperBound: BitRangeBound?
}

extension BitRange {
  /// Returns the lower bound as if this bit-range were a `ClosedRange<Int>`.
  var canonicalizedLowerBound: Int {
    guard let lowerBound = self.lowerBound else { return .min }
    return lowerBound.inclusive ? lowerBound.value : lowerBound.value + 1
  }

  /// Returns the upper bound as if this bit-range were a `ClosedRange<Int>`
  /// if present.
  var canonicalizedUpperBound: Int {
    guard let upperBound = self.upperBound else { return .max }
    return upperBound.inclusive ? upperBound.value : upperBound.value - 1
  }

  /// Returns the `ClosedRange<Int>` represented by this bit-range.
  var canonicalizedClosedRange: ClosedRange<Int> {
    self.canonicalizedLowerBound...self.canonicalizedUpperBound
  }
}

extension BitRange: CustomStringConvertible {
  var description: String {
    var description = ""
    if let lowerBound = self.lowerBound {
      description.append(lowerBound.inclusive ? "[" : "(")
      description.append("\(lowerBound.value)")
    } else {
      description.append("(-∞")
    }
    description.append(", ")
    if let upperBound = self.upperBound {
      description.append("\(upperBound.value)")
      description.append(upperBound.inclusive ? "]" : ")")
    } else {
      description.append("+∞)")
    }
    return description
  }
}

extension BitRange: Equatable {}

extension BitRange: ExpressibleByExprSyntax {
  init(
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    if let sequence = expression.as(SequenceExprSyntax.self) {
      let folded = try OperatorTable.standardOperators.foldSingle(sequence)
      guard !folded.is(SequenceExprSyntax.self) else {
        throw context.error(at: expression, message: .expectedRangeLiteral())
      }
      try self.init(original: expression, expression: folded, in: context)
    } else {
      try self.init(original: expression, expression: expression, in: context)
    }
  }

  init(
    original: ExprSyntax,
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    let lowerBoundExpression: ExprSyntax?
    let operatorText: String
    let upperBoundExpression: ExprSyntax?

    switch Syntax(expression).as(SyntaxEnum.self) {
    case .declReferenceExpr(let decl):
      lowerBoundExpression = nil
      operatorText = decl.baseName.text
      upperBoundExpression = nil

    case .prefixOperatorExpr(let prefix):
      lowerBoundExpression = nil
      operatorText = prefix.operator.text
      upperBoundExpression = prefix.expression

    case .infixOperatorExpr(let infix):
      lowerBoundExpression = infix.leftOperand
      guard let op = infix.operator.as(BinaryOperatorExprSyntax.self) else {
        throw context.error(at: original, message: .expectedRangeLiteral())
      }
      operatorText = op.operator.text
      upperBoundExpression = infix.rightOperand

    case .postfixOperatorExpr(let postfix):
      lowerBoundExpression = postfix.expression
      operatorText = postfix.operator.text
      upperBoundExpression = nil

    default:
      throw context.error(at: original, message: .expectedRangeLiteral())
    }

    let upperBoundInclusive: Bool
    switch operatorText {
    case "..<":
      upperBoundInclusive = false
    case "...":
      upperBoundInclusive = true
    default:
      throw context.error(at: original, message: .expectedRangeLiteral())
    }

    if let lowerBoundExpression = lowerBoundExpression {
      let value = try Int(expression: lowerBoundExpression, in: context)
      self.lowerBound = .init(value: value, inclusive: true)
    }

    if let upperBoundExpression = upperBoundExpression {
      let value = try Int(expression: upperBoundExpression, in: context)
      self.upperBound = .init(value: value, inclusive: upperBoundInclusive)
    }

    guard self.canonicalizedLowerBound <= self.canonicalizedUpperBound else {
      throw context.error(at: original, message: .expectedRangeLiteral())
    }
  }
}

extension BitRange: ExpressibleByStringLiteral {
  init(stringLiteral description: String) {
    guard let value = Self(description) else {
      preconditionFailure("Invalid BitRange string literal '\(description)'")
    }
    self = value
  }
}

extension BitRange: LosslessStringConvertible {
  init?(_ description: String) {
    var input = description[...]

    if let _ = Parser("(-∞").run(&input) {
      self.lowerBound = nil
    } else {
      let parser =
        Parser
        .take(
          .oneOf([
            Parser("(").map { false },
            Parser("[").map { true },
          ])
        )
        .take(.swiftInteger)

      guard let value = parser.run(&input) else { return nil }
      self.lowerBound = .init(value: value.1, inclusive: value.0)
    }

    guard let _ = Parser(", ").run(&input) else { return nil }

    if let _ = Parser("+∞)").run(&input) {
      self.upperBound = nil
    } else {
      let parser =
        Parser
        .take(.swiftInteger)
        .take(
          .oneOf([
            Parser(")").map { false },
            Parser("]").map { true },
          ]))

      guard let value = parser.run(&input) else { return nil }
      self.upperBound = .init(value: value.0, inclusive: value.1)
    }

    guard input.isEmpty else { return nil }
  }
}

extension ErrorDiagnostic {
  static func expectedRangeLiteral() -> Self {
    .init("'\(Macro.signature)' requires expression to be a range literal")
  }
}
