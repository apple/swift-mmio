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
import MMIOUtilities

#if canImport(FoundationXML)
import FoundationXML
#endif

@XMLElement
public struct SVDEnumerationCaseDataValue {
  public var value: SVDEnumerationCaseDataValueValue
}

extension SVDEnumerationCaseDataValue {
  public func bitPatterns() -> [UInt64] { [] }
}

extension SVDEnumerationCaseDataValue: Decodable {}

extension SVDEnumerationCaseDataValue: Encodable {}

extension SVDEnumerationCaseDataValue: Equatable {}

extension SVDEnumerationCaseDataValue: Hashable {}
