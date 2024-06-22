//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// FIXME: Support path based derivedFrom
// CMSIS-SVD 1.3.9: /device/pripherals/peripheral/registers/.../cluster element
// Specify the cluster name from which to inherit data. Elements specified
// subsequently override inherited values.
//
// Always use the full qualifying path, which must start with the
// peripheral `<name>`, when deriving from another scope. (for example, in
// peripheral B, derive from `peripheralA.clusterX`).
//
// You can use the cluster `<name>` when both clusters are in the same
// scope. No relative paths will work.

protocol SVDDerivable {
  static var kind: String { get }
  var name: String { get }
  var derivedFrom: String? { get }
  mutating func merging(_ other: Self)
}
