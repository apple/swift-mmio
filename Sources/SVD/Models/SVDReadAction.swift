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

/// Side effects of a read.
public enum SVDReadAction: String {
  /// The field is cleared (set to zero) following a read operation.
  case clear
  /// The field is set (set to ones) following a read operation.
  case set
  /// The field is modified in some way after a read operation.
  case modify
  /// One or more dependent resources other than the current field are
  /// immediately affected by a read operation (it is recommended that the
  /// field description specifies these dependencies).
  case modifyExternal
}

extension SVDReadAction: Decodable {}

extension SVDReadAction: Encodable {}

extension SVDReadAction: Equatable {}

extension SVDReadAction: Hashable {}

extension SVDReadAction: Sendable {}

extension SVDReadAction: XMLNodeInitializable {}
