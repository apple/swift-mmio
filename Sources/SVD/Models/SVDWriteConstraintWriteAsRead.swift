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
public struct SVDWriteConstraintWriteAsRead {
  public var writeAsRead: Bool
}

extension SVDWriteConstraintWriteAsRead: Decodable {}

extension SVDWriteConstraintWriteAsRead: Encodable {}

extension SVDWriteConstraintWriteAsRead: Equatable {}

extension SVDWriteConstraintWriteAsRead: Hashable {}

extension SVDWriteConstraintWriteAsRead: Sendable {}
