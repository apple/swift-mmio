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

extension DeclGroupSyntax {
  func allBitRanges(
    with context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> [BitRange] {
    let attributeNames = [
      "ReadOnly",
      "ReadWrite",
      "Reserved",
      "WriteOnly",
    ]
    return try memberBlock.members
      .compactMap {
        VariableDeclSyntax($0.decl)?.attributes
          .compactMap {
            AttributeSyntax($0)
          }
          .filter {
            attributeNames.contains(IdentifierTypeSyntax($0.attributeName)?.name.text ?? "" )
          }
          .compactMap {
            LabeledExprListSyntax($0.arguments)
          }
      }
      .flatMap({ $0 }) // All the LabeledExprLists in interest
      .reduce(into: [BitRange](), { partialResult, labeledExprList in
        var bits = false
        for labeledExpr in labeledExprList {
          if let label = labeledExpr.label {
            bits = label.text == "bits"
          }
          if bits {
            partialResult.append(try BitRange(expression: labeledExpr.expression, in: context))
          }
        }
      })
  }
}
