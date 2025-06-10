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

/// Specify the security privilege to access an address region.
///
/// This information is relevant for the programmer as well as the debugger when
/// no universal access permissions have been granted. If no specific
/// information is provided, an address region is accessible in any mode.
public enum SVDProtection: String {
  /// Secure permission required for access.
  case secure = "s"
  /// Non-secure or secure permission required for access.
  case nonSecure = "n"
  /// Privileged permission required for access.
  case privileged = "p"
}

extension SVDProtection: Decodable {}

extension SVDProtection: Encodable {}

extension SVDProtection: Equatable {}

extension SVDProtection: Hashable {}

extension SVDProtection: XMLElementInitializable {}

extension SVDProtection: Sendable {}
