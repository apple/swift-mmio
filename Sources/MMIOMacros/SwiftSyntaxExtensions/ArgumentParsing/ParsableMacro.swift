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

private var signatureCache =
  [AnyHashable: (String, AttributeListSyntax.Element)]()

protocol ParsableMacro {
  static var baseName: String { get }
  init()
  // FIXME: Maybe replace by grabbing a runtime function using @_silgen_name
  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws
}

extension ParsableMacro {
  static var baseName: String {
    let suffix = "Macro"
    var baseName = "\(Self.self)"
    if baseName.hasSuffix(suffix) {
      baseName = String(baseName.dropLast(suffix.count))
    }
    return baseName
  }
}

extension ParsableMacro {
  private static func signatures() -> (String, AttributeListSyntax.Element) {
    let key = ObjectIdentifier(Self.self)
    if let signatures = signatureCache[key] { return signatures }

    // Avoid calling computed property multiple times.
    let baseName = Self.baseName

    var signature = "@\(baseName)"
    var attributeWithPlaceholders = AttributeSyntax(
      atSign: .atSignToken(),
      attributeName: TypeSyntax(stringLiteral: baseName))
    var arguments = LabeledExprListSyntax()

    for child in Mirror(reflecting: Self()).children {
      guard let child = child.value as? any ArgumentProtocol else { continue }
      if arguments.isEmpty {
        signature += "("
        attributeWithPlaceholders.leftParen = .leftParenToken()
        arguments = .init()
      }
      signature.append(child.label)
      signature.append(":")

      let argument = LabeledExprSyntax(
        label: .identifier(child.label),
        colon: .colonToken(trailingTrivia: .space),
        expression: EditorPlaceholderExprSyntax(
          placeholder: .identifier("<#\(child.typePlaceholder)#>")))

      if !arguments.isEmpty {
        let lastIndex = arguments.index(before: arguments.endIndex)
        arguments[lastIndex].trailingComma = .commaToken(trailingTrivia: .space)
      }

      arguments.append(argument)
    }

    if !arguments.isEmpty {
      signature += ")"
      attributeWithPlaceholders.arguments = .argumentList(arguments)
      attributeWithPlaceholders.rightParen = .rightParenToken()
    }

    let attribute: AttributeListSyntax.Element =
      .attribute(attributeWithPlaceholders)
    signatureCache[key] = (signature, attribute)
    return (signature, attribute)
  }

  static var signature: String {
    Self.signatures().0
  }

  static var attributeWithPlaceholders: AttributeListSyntax.Element {
    Self.signatures().1
  }
}

extension ParsableMacro {
  init(
    from node: AttributeSyntax,
    // FIXME: macro == Self
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    // Construct an instance of the macro with no arguments parsed into instance
    // properties.
    self.init()

    let expressions =
      node.arguments?.as(LabeledExprListSyntax.self)
      ?? LabeledExprListSyntax()
    let children = Mirror(reflecting: self).children

    var expressionIndex = expressions.startIndex
    var childIndex = children.startIndex
    var previousLabelMatched = false

    // Walk the expressions and the children together, matching expressions to
    // children using argument labels.
    while expressionIndex != expressions.endIndex,
      childIndex != children.endIndex
    {

      let expression = expressions[expressionIndex]
      let child = children[childIndex]

      // We only care about @Argument child properties so skip all others.
      guard let child = child.value as? any ArgumentProtocol else {
        children.formIndex(after: &childIndex)
        continue
      }

      func updateChildAndIncrementExpressionIndex() throws {
        // FIXME: Leverage reflection instead of user provided dispatch method
        // try child.update(from: expression.expression, in: context)
        try self.update(
          label: child.label,
          from: expression.expression,
          in: context)
        // Save that we just matched a label, so if the next expression has no
        // label, we will update the same child. Next move only the expression
        // index forward.
        previousLabelMatched = true
        expressions.formIndex(after: &expressionIndex)
      }

      if expression.label?.text == child.label {
        // If the expression label matches the child then attempt to update
        // child with the expression.
        try updateChildAndIncrementExpressionIndex()
      } else if expression.label?.text == nil, previousLabelMatched {
        // If the expression has no label and the previous expression's label
        // matched, then parse into the same child, e.g. a variadic argument.
        try updateChildAndIncrementExpressionIndex()
      } else if expression.label?.text != nil, previousLabelMatched {
        // If the expression has a label and the previous expression's label
        // matched, then we need to move to the next child and attempt to match
        // it's label.
        previousLabelMatched = false
        children.formIndex(after: &childIndex)
      } else if child.isParsed {
        // If the expression has a label and does not match the current child's
        // label and child has already been parsed, then we need to move to the
        // next child and attempt to match it's label.
        previousLabelMatched = false
        children.formIndex(after: &childIndex)
      } else {
        throw context.error(
          at: expression,
          message: .unexpectedArgumentLabel(
            expected: child.label,
            actual: expression.label?.text ?? "_"))
      }
    }

    // Move past the last child which was parsed.
    if previousLabelMatched {
      children.formIndex(after: &childIndex)
    }

    // Check that all expressions have been consumed.
    if expressionIndex != expressions.endIndex {
      let expression = expressions[expressionIndex]
      throw context.error(
        at: expression,
        message: .unexpectedExtraArgument(label: expression.label?.text ?? "_"))
    }

    // Check that all children have been parsed.
    while childIndex != children.endIndex {
      let child = children[childIndex]
      guard
        let child = child.value as? any ArgumentProtocol,
        !child.isParsed
      else {
        children.formIndex(after: &childIndex)
        continue
      }
      throw context.error(
        at: expressions.isEmpty ? Syntax(node) : Syntax(expressions),
        message: .unexpectedMissingArgument(label: child.label))
    }
  }
}

extension ErrorDiagnostic {
  static func unexpectedArgumentLabel(
    expected: String,
    actual: String
  ) -> Self {
    .init(
      """
      '\(Macro.signature)' internal error. Incorrect label for argument, \
      expected '\(expected)', but found '\(actual)'. \(Self.internalErrorSuffix)
      """)
  }

  static func unexpectedExtraArgument(label: String) -> Self {
    .init(
      """
      '\(Macro.signature)' internal error. Unexpected additional argument \
      '\(label)'. \(Self.internalErrorSuffix)
      """)
  }

  static func unexpectedMissingArgument(label: String) -> Self {
    .init(
      """
      '\(Macro.signature)' internal error. Missing argument '\(label)'. \
      \(Self.internalErrorSuffix)
      """)
  }
}
