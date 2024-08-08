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

/// Specifies what access types an enumeratedValues set is associated with.
public enum SVDEnumerationUsage: String {
  case read
  case write
  case readWrite = "read-write"
}

extension SVDEnumerationUsage: Decodable {}

extension SVDEnumerationUsage: Encodable {}

extension SVDEnumerationUsage: Equatable {}

extension SVDEnumerationUsage: Hashable {}

extension SVDEnumerationUsage: XMLNodeInitializable {}
