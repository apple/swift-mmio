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
  /// Returns the lower bound as if the bound were inclusive.
  var inclusiveLowerBound: Int? {
    guard let lowerBound = self.lowerBound else { return nil }
    return lowerBound.inclusive ? lowerBound.value : lowerBound.value + 1
  }

  /// Returns the lower bound as if this bit-range were a `ClosedRange<Int>`.
  var canonicalizedLowerBound: Int {
    self.inclusiveLowerBound ?? .min
  }

  /// Returns the upper bound as if the bound were inclusive.
  var inclusiveUpperBound: Int? {
    guard let upperBound = self.upperBound else { return nil }
    return upperBound.inclusive ? upperBound.value : upperBound.value - 1
  }

  /// Returns the upper bound as if this bit-range were a `ClosedRange<Int>`.
  var canonicalizedUpperBound: Int {
    self.inclusiveUpperBound ?? .max
  }

  /// Returns the `ClosedRange<Int>` represented by this bit-range.
  var canonicalizedClosedRange: ClosedRange<Int> {
    self.canonicalizedLowerBound...self.canonicalizedUpperBound
  }
}

extension BitRange {
  func rangeOverlapping(_ other: Self) -> Range<Int>? {
    let (lhs, rhs) = self <= other ? (self, other) : (other, self)

    let lhsLowerBound = lhs.canonicalizedLowerBound
    let lhsUpperBound = lhs.canonicalizedUpperBound
    let rhsLowerBound = rhs.canonicalizedLowerBound
    let rhsUpperBound = rhs.canonicalizedUpperBound

    //      lower   lower           upper   upper
    //      ╎       ╎               ╎       ╎
    // lhs: •───────────────────────◦       ╎
    // rhs: ╎       •───────────────────────◦
    guard rhsLowerBound <= lhsUpperBound else {
      return nil
    }

    let lowerBound = max(lhsLowerBound, rhsLowerBound)
    var upperBound = min(lhsUpperBound, rhsUpperBound)
    if upperBound < .max {
      upperBound += 1
    }
    return lowerBound..<upperBound
  }
}

extension BitRange: Comparable {
  static func < (lhs: BitRange, rhs: BitRange) -> Bool {
    guard lhs.canonicalizedLowerBound == rhs.canonicalizedLowerBound else {
      return lhs.canonicalizedLowerBound < rhs.canonicalizedLowerBound
    }
    guard lhs.canonicalizedUpperBound == rhs.canonicalizedUpperBound else {
      return lhs.canonicalizedUpperBound < rhs.canonicalizedUpperBound
    }
    return false
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
      // A sequence which did not fold into a single expression is diagnosed
      // by the initializer below.
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
    // An integer bit index, e.g. the `3` in `@ReadWrite(bits: 3)`, describes
    // the single-bit range `3...3`.
    if let bitIndex = Self.integer(from: expression) {
      self.lowerBound = .init(value: bitIndex, inclusive: true)
      self.upperBound = .init(value: bitIndex, inclusive: true)
      return
    }

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
        throw context.error(
          at: original, message: .expectedIntegerOrRangeLiteral())
      }
      operatorText = op.operator.text
      upperBoundExpression = infix.rightOperand

    case .postfixOperatorExpr(let postfix):
      lowerBoundExpression = postfix.expression
      operatorText = postfix.operator.text
      upperBoundExpression = nil

    default:
      throw context.error(
        at: original, message: .expectedIntegerOrRangeLiteral())
    }

    let upperBoundInclusive: Bool
    switch operatorText {
    case "..<":
      upperBoundInclusive = false
    case "...":
      upperBoundInclusive = true
    default:
      throw context.error(
        at: original, message: .expectedIntegerOrRangeLiteral())
    }

    func bound(_ expression: ExprSyntax) throws -> Int {
      guard let value = Self.integer(from: expression) else {
        throw context.error(at: expression, message: .expectedIntegerLiteral())
      }
      return value
    }

    if let lowerBoundExpression = lowerBoundExpression {
      let value = try bound(lowerBoundExpression)
      self.lowerBound = .init(value: value, inclusive: true)
    }

    if let upperBoundExpression = upperBoundExpression {
      let value = try bound(upperBoundExpression)
      self.upperBound = .init(value: value, inclusive: upperBoundInclusive)
    }

    guard self.canonicalizedLowerBound <= self.canonicalizedUpperBound else {
      throw context.error(at: original, message: .expectedNonEmptyRange())
    }
  }

  /// Returns the value of an integer literal expression, such as the `3` in
  /// `@ReadWrite(bits: 3)` or the `-3` in `@ReadWrite(bits: -3..<4)`, or nil
  /// if the expression is not an integer literal.
  ///
  /// A leading '-' is accepted so that negative bit indices and range bounds
  /// are diagnosed as outside the register's bounds instead of as malformed
  /// values.
  private static func integer(from expression: ExprSyntax) -> Int? {
    if let integerLiteral = expression.as(IntegerLiteralExprSyntax.self) {
      return integerLiteral.value
    }

    guard
      let prefixOperator = expression.as(PrefixOperatorExprSyntax.self),
      prefixOperator.operator.text == "-",
      let integerLiteral =
        prefixOperator.expression.as(IntegerLiteralExprSyntax.self)
    else { return nil }

    return integerLiteral.negatedValue
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
    guard let value = BitRangeParser().parseAll(description)
    else { return nil }
    self = value
  }
}

extension ErrorDiagnostic {
  static func expectedNonEmptyRange() -> Self {
    .init("'\(Macro.signature)' requires expression to be a non-empty range")
  }

  static func expectedIntegerOrRangeLiteral() -> Self {
    .init(
      """
      '\(Macro.signature)' requires expression to be an integer or range literal
      """)
  }
}

private struct BitRangeParser: ParserProtocol {
  typealias Output = BitRange

  func parse(_ input: inout Input) -> Output? {
    let original = input

    let lowerBound: BitRangeBound?
    if DropParser("(-∞").parse(&input) != nil {
      lowerBound = nil
    } else {
      let inclusiveParser = OneOfParser<Bool>(
        ("(", false),
        ("[", true),
      )

      guard
        let inclusive = inclusiveParser.parse(&input),
        let value = SwiftIntegerParser<Int>().parse(&input)
      else {
        input = original
        return nil
      }

      lowerBound = .init(value: value, inclusive: inclusive)
    }

    guard DropParser(", ").parse(&input) != nil else {
      input = original
      return nil
    }

    let upperBound: BitRangeBound?
    if DropParser("+∞)").parse(&input) != nil {
      upperBound = nil
    } else {
      let inclusiveParser = OneOfParser<Bool>(
        (")", false),
        ("]", true),
      )

      guard
        let value = SwiftIntegerParser<Int>().parse(&input),
        let inclusive = inclusiveParser.parse(&input)
      else {
        input = original
        return nil
      }

      upperBound = .init(value: value, inclusive: inclusive)
    }

    return BitRange(lowerBound: lowerBound, upperBound: upperBound)
  }
}
