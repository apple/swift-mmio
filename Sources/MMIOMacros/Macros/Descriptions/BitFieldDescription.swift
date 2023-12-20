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
  var accessLevel: DeclModifierSyntax?
  var bitWidth: Int
  var type: any BitFieldMacro.Type
  var fieldName: IdentifierPatternSyntax
  var fieldType: TypeSyntax
  var bitRanges: [BitRange]
  var projectedType: ExprSyntax?
}

extension BitFieldDescription {
  // FIXME: compute this once
  func storageType() -> DeclReferenceExprSyntax {
    .init(baseName: .identifier("UInt\(self.bitWidth)"))
  }
}

extension BitFieldDescription {
  func validate() throws {
    // FIXME: Validate bit range overlap
  }
}

extension BitFieldDescription {
  func bitRangeExpression(_ bitRange: BitRange) -> ExprSyntax {
    let clampedRange = bitRange
      .canonicalizedClosedRange
      .clamped(to: 0...(self.bitWidth - 1))
    let infix = InfixOperatorExprSyntax(
      leftOperand: IntegerLiteralExprSyntax(clampedRange.lowerBound),
      operator: BinaryOperatorExprSyntax(operator: .binaryOperator("..<")),
      rightOperand: IntegerLiteralExprSyntax(clampedRange.upperBound + 1)
    )
    guard let expression = infix.as(ExprSyntax.self) else {
      preconditionFailure("InfixOperatorExprSyntax must be an ExprSyntax")
    }
    return expression
  }

  func declarations() -> [DeclSyntax] {
    switch bitRanges.count {
    case 0:
      preconditionFailure()
    case 1:
      let bitRangeExpression = self.bitRangeExpression(self.bitRanges[0])
      return [
        """
        \(self.accessLevel)enum \(self.fieldType): ContiguousBitField {
          \(self.accessLevel)typealias Storage = \(self.storageType())
          \(self.accessLevel)static let bitRange = \(bitRangeExpression)
        }
        """
      ]
    default:
      let bitRangeExpressions = self
        .bitRanges
        .map { self.bitRangeExpression($0) }
      return [
        """
        \(self.accessLevel)enum \(self.fieldType): DiscontiguousBitField {
          \(self.accessLevel)typealias Storage = \(self.storageType())
          \(self.accessLevel)static let bitRanges = \(ArrayExprSyntax(expressions: bitRangeExpressions))
        }
        """
      ]
    }
  }
}

extension BitFieldDescription {
  func rawVariableDeclaration() -> DeclSyntax {
    """
    \(self.accessLevel)var \(self.fieldName): \(self.storageType()) {
      @inlinable @inline(__always) get {
        \(self.fieldType).extract(from: self.storage)
      }
      @inlinable @inline(__always) set {
        \(self.fieldType).insert(newValue, into: &self.storage)
      }
    }
    """
  }

  func readWriteVariableDeclaration() -> DeclSyntax? {
    guard
      self.type.isReadable,
      self.type.isWriteable,
      let projectedType = self.projectedType
    else {
      return nil
    }

    return """
      \(self.accessLevel)var \(self.fieldName): \(projectedType) {
        @inlinable @inline(__always) get {
          preconditionMatchingBitWidth(\(self.fieldType).self, \(projectedType).self)
          return \(projectedType)(storage: self.raw.\(self.fieldName))
        }
        @inlinable @inline(__always) set {
          preconditionMatchingBitWidth(\(self.fieldType).self, \(projectedType).self)
          self.raw.\(self.fieldName) = newValue.storage(Self.Value.Raw.Storage.self)
        }
      }
      """
  }

  func readVariableDeclaration() -> DeclSyntax? {
    guard
      self.type.isReadable,
      let projectedType = self.projectedType
    else {
      return nil
    }

    return """
      \(self.accessLevel)var \(self.fieldName): \(projectedType) {
        @inlinable @inline(__always) get {
          preconditionMatchingBitWidth(\(self.fieldType).self, \(projectedType).self)
          return \(projectedType)(storage: self.raw.\(self.fieldName))
        }
      }
      """
  }

  func writeVariableDeclaration() -> DeclSyntax? {
    guard
      self.type.isWriteable,
      let projectedType = self.projectedType
    else {
      return nil
    }

    // FIXME: improve warning message
    // blocked-by: rdar://116130327 (Customizable deprecation messages)

    return """
      \(self.accessLevel)var \(self.fieldName): \(projectedType) {
        @available(*, deprecated, message: "API misuse; read from write view returns the value to be written, not the value initially read.")
        @inlinable @inline(__always) get {
          preconditionMatchingBitWidth(\(self.fieldType).self, \(projectedType).self)
          return \(projectedType)(storage: self.raw.\(self.fieldName))
        }
        @inlinable @inline(__always) set {
          preconditionMatchingBitWidth(\(self.fieldType).self, \(projectedType).self)
          self.raw.\(self.fieldName) = newValue.storage(Self.Value.Raw.Storage.self)
        }
      }
      """
  }
}
