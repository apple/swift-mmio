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

#if canImport(FoundationXML)
import FoundationXML
#else
import Foundation
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
}

extension SVDRegisterProperties {
  public func merged(_ other: SVDRegisterProperties) -> SVDRegisterProperties {
    SVDRegisterProperties(
      size: size ?? other.size,
      access: access ?? other.access,
      protection: protection ?? other.protection,
      resetValue: resetValue ?? other.resetValue,
      resetMask: resetMask ?? other.resetMask)
  }
}
