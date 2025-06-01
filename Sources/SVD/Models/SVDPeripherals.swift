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

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

/// All peripherals of a device are enclosed within the tag `<peripherals>`.
@XMLElement
public struct SVDPeripherals {
  /// Define the sequence of peripherals.
  public var peripheral: [SVDPeripheral]
}

extension SVDPeripherals: Decodable {}

extension SVDPeripherals: Encodable {}

extension SVDPeripherals: Equatable {}

extension SVDPeripherals: Hashable {}

extension SVDPeripherals: Sendable {}
