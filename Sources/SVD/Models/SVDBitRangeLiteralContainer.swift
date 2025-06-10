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
import MMIOUtilities

@XMLElement
public struct SVDBitRangeLiteralContainer {
  public var bitRange: SVDBitRangeLiteral
}

extension SVDBitRangeLiteralContainer: Decodable {}

extension SVDBitRangeLiteralContainer: Encodable {}

extension SVDBitRangeLiteralContainer: Equatable {}

extension SVDBitRangeLiteralContainer: Hashable {}

extension SVDBitRangeLiteralContainer: Sendable {}
