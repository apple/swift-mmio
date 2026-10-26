//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A type that describes the bits of a bit field in a bit field macro, such as
/// ``MMIO/ReadWrite(bits:as:)``.
///
/// A range literal with integer bounds describes the bits in the range. You
/// can use different kinds of ranges together in one macro, for example
/// `@ReadWrite(bits: 0..<2, 4...5)`. The first item provides the least
/// significant bits of the field.
///
/// The bit field macros read the bits from the source text of the macro
/// arguments. Do not add conformances to this protocol.
@_marker public protocol BitRangeExpression {}

extension Range: BitRangeExpression where Bound: BinaryInteger {}

extension ClosedRange: BitRangeExpression where Bound: BinaryInteger {}

extension PartialRangeFrom: BitRangeExpression where Bound: BinaryInteger {}

extension PartialRangeThrough: BitRangeExpression where Bound: BinaryInteger {}

extension PartialRangeUpTo: BitRangeExpression where Bound: BinaryInteger {}
