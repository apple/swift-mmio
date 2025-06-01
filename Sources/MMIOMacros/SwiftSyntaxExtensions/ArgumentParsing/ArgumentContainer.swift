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

struct ParsedArgument<Value>: Sendable where Value: Sendable {
  var value: Value
  var expression: ExprSyntax
}

protocol ArgumentContainer: Sendable {
  associatedtype Value: ExpressibleByExprSyntax
  associatedtype WrappedValue
  associatedtype WrappedExpression
  var value: WrappedValue { get }
  var expression: WrappedExpression { get }

  init(
    initial: Self?,
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws
}

struct ExactlyOne<Value> where Value: ExpressibleByExprSyntax, Value: Sendable {
  var parsed: ParsedArgument<Value>
}

extension ExactlyOne: ArgumentContainer {
  typealias WrappedValue = Value
  typealias WrappedExpression = ExprSyntax
  var value: WrappedValue { self.parsed.value }
  var expression: WrappedExpression { self.parsed.expression }

  init(
    initial: Self?,
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    guard initial == nil else {
      throw context.error(
        at: expression,
        message: .expectedExactlyOneArgumentValue(label: label))
    }
    let value = try Value(expression: expression, in: context)
    self.init(parsed: .init(value: value, expression: expression))
  }
}

struct ZeroOrOne<Value> where Value: ExpressibleByExprSyntax, Value: Sendable {
  var parsed: ParsedArgument<Value>?
}

extension ZeroOrOne: ArgumentContainer {
  typealias WrappedValue = Value?
  typealias WrappedExpression = ExprSyntax?
  var value: WrappedValue { self.parsed?.value }
  var expression: WrappedExpression { self.parsed?.expression }

  init(
    initial: Self?,
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    if let initial = initial, initial.parsed != nil {
      throw context.error(
        at: expression,
        message: .expectedZeroOrOneArgumentValues(label: label))
    }
    let value = try Value(expression: expression, in: context)
    self.init(parsed: .init(value: value, expression: expression))
  }
}

struct OneOrMore<Value> where Value: ExpressibleByExprSyntax, Value: Sendable {
  var parsed: [ParsedArgument<Value>]
}

extension OneOrMore: ArgumentContainer {
  typealias WrappedValue = [Value]
  typealias WrappedExpression = [ExprSyntax]
  var value: WrappedValue { self.parsed.map(\.value) }
  var expression: WrappedExpression { self.parsed.map(\.expression) }

  init(
    initial: Self?,
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    self = initial ?? .init(parsed: [])
    let value = try Value(expression: expression, in: context)
    self.parsed.append(.init(value: value, expression: expression))
  }
}

extension ErrorDiagnostic {
  static func expectedExactlyOneArgumentValue(label: String) -> Self {
    .init(
      """
      '\(Macro.signature)' argument '\(label)' must be passed exactly one value
      """)
  }

  static func expectedZeroOrOneArgumentValues(label: String) -> Self {
    .init(
      """
      '\(Macro.signature)' argument '\(label)' must be passed zero or one values
      """)
  }
}
