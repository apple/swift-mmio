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

struct BitFieldDescription {
  var accessLevel: AccessLevel?
  var bitWidth: Int
  var type: any BitFieldMacro.Type
  var fieldName: IdentifierPatternSyntax
  var fieldType: TypeSyntax
  var bitRanges: [Range<Int>]
  var bitRangeExpressions: [ExprSyntax]
  var projectedType: Int?
}

extension BitFieldDescription {
  func validate() throws {
    // FIXME: Validate bit range overlap
  }

  func declarations() -> [DeclSyntax] {
    switch bitRangeExpressions.count {
    case 0:
      preconditionFailure()
    case 1:
      let bitRange = self.bitRangeExpressions[0]
      return [
        """
        \(self.accessLevel)enum \(self.fieldType): ContiguousBitField {
          \(self.accessLevel)typealias Storage = UInt\(raw: self.bitWidth)
          \(self.accessLevel)static let bitRange = \(bitRange)
        }
        """
      ]
    default:
      let bitRanges = ArrayExprSyntax(expressions: self.bitRangeExpressions)
      return [
        """
        \(self.accessLevel)enum \(self.fieldType): DiscontiguousBitField {
          \(self.accessLevel)typealias Storage = UInt\(raw: self.bitWidth)
          \(self.accessLevel)static let bitRange = \(bitRanges)
        }
        """
      ]
    }
  }
}
