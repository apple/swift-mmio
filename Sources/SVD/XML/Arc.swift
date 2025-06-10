//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

class Arc<Wrapped> {
  var wrapped: Wrapped

  init(_ wrapped: Wrapped) {
    self.wrapped = wrapped
  }
}

extension Arc: CustomStringConvertible where Wrapped: CustomStringConvertible {
  var description: String { self.wrapped.description }
}
