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
public struct SVDWriteConstraintRange {
  public var minimum: UInt64
  public var maximum: UInt64
}

extension SVDWriteConstraintRange: Decodable {}

extension SVDWriteConstraintRange: Encodable {}

extension SVDWriteConstraintRange: Equatable {}

extension SVDWriteConstraintRange: Hashable {}

extension SVDWriteConstraintRange: Sendable {}
