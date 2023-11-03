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

protocol ArgumentProtocol {
  var label: String { get }
  var isParsed: Bool { get }
  var typePlaceholder: String { get }

  mutating func update(
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws
}

@propertyWrapper
struct Argument<Container: ArgumentContainer>: ArgumentProtocol {
  var label: String
  var container: Container?
  var isParsed: Bool { self.container != nil }
  var typePlaceholder: String { "\(Container.Value.self)" }

  var wrappedValue: Container.WrappedValue {
    guard let container = self.container else {
      fatalError("Internal macro parsing error.")
    }
    return container.value
  }

  var projectedValue: Container.WrappedExpression {
    guard let container = self.container else {
      fatalError("Internal macro parsing error.")
    }
    return container.expression
  }

  mutating func update(
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    let newContainer = try Container(
      initial: self.container,
      label: self.label,
      from: expression,
      in: context)
    self.container = newContainer
  }
}

extension Argument {
  init<T>(label: String) where T: ExpressibleByExprSyntax, Container == ExactlyOne<T> {
    self.label = label
    self.container = nil
  }

  init<T>(label: String) where T: ExpressibleByExprSyntax, Container == ZeroOrOne<T> {
    self.label = label
    self.container = .init(parsed: nil)
  }

  init<T>(label: String) where T: ExpressibleByExprSyntax, Container == OneOrMore<T> {
    self.label = label
    self.container = nil
  }
}
