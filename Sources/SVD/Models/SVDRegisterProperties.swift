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

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

@XMLElement
public struct SVDRegisterProperties {
  /// Defines the default bit-width of any register contained in the device
  /// (implicit inheritance).
  public var size: UInt64?
  /// Defines the default access rights for all registers.
  public var access: SVDAccess?
  /// Defines the protection rights for all registers.
  public var protection: SVDProtection?
  /// Defines the default value for all registers at Reset.
  public var resetValue: UInt64?
  /// Identifies which register bits have a defined reset value.
  public var resetMask: UInt64?

  public init(
    size: UInt64?,
    access: SVDAccess?,
    protection: SVDProtection?,
    resetValue: UInt64?,
    resetMask: UInt64?
  ) {
    self.size = size
    self.access = access
    self.protection = protection
    self.resetValue = resetValue
    self.resetMask = resetMask
  }
}

extension SVDRegisterProperties {
  public static let none = SVDRegisterProperties()

  public init() {
    self.size = nil
    self.access = nil
    self.protection = nil
    self.resetValue = nil
    self.resetMask = nil
  }

  public func merging(_ other: Self) -> Self {
    SVDRegisterProperties(
      size: self.size ?? other.size,
      access: self.access ?? other.access,
      protection: self.protection ?? other.protection,
      resetValue: self.resetValue ?? other.resetValue,
      resetMask: self.resetMask ?? other.resetMask)
  }

  public mutating func merged(with other: Self) {
    self = self.merging(other)
  }
}

extension SVDRegisterProperties: Decodable {}

extension SVDRegisterProperties: Encodable {}

extension SVDRegisterProperties: Equatable {}

extension SVDRegisterProperties: Hashable {}
