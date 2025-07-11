//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension FixedWidthInteger {
  public func roundUp(toMultipleOf powerOfTwo: Self) -> Self {
    // Check that powerOfTwo really is a power of two.
    precondition(powerOfTwo > 0 && powerOfTwo & (powerOfTwo &- 1) == 0)
    // Round up and return. This may overflow and trap, but only if the rounded
    // result would have overflowed anyway.
    return (self + (powerOfTwo &- 1)) & (0 &- powerOfTwo)
  }

  public func roundedUpToPowerOfTwo() -> Self {
    if self == 0 { return 0 }
    let shifts = self.bitWidth &- self.leadingZeroBitCount
    return self.nonzeroBitCount == 1 ? self : 1 &<< shifts
  }
}
