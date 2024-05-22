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

/// A test pseudo random number generator.
///
/// Algorithm from https://en.wikipedia.org/wiki/Permuted_congruential_generator
struct SVD2LLDBTestPRNG: RandomNumberGenerator {
  static let multiplier: UInt64 = 6_364_136_223_846_793_005
  static let increment: UInt64 = 1_442_695_040_888_963_407

  var state: UInt64

  init(seed: UInt64) {
    self.state = seed &+ Self.increment
    _ = self.next()
  }

  private func rotr32(x: UInt32, r: UInt32) -> UInt32 {
    (x &>> r) | x &<< ((~r &+ 1) & 31)
  }

  mutating func next32() -> UInt32 {
    var x = self.state
    let count = UInt32(x &>> 59)
    self.state = x &* Self.multiplier &+ Self.increment
    x ^= x &>> 18
    return self.rotr32(x: UInt32(truncatingIfNeeded: x &>> 27), r: count)
  }

  mutating func next() -> UInt64 {
    UInt64(self.next32()) << 32 | UInt64(self.next32())
  }
}
