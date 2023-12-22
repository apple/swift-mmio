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

public enum SVDDataType: String {
  /// Unsigned byte.
  case uint8 = "uint8_t"
  /// Unsigned half word.
  case uint16 = "uint16_t"
  /// Unsigned word.
  case uint32 = "uint32_t"
  /// Unsigned double word.
  case uint64 = "uint64_t"
  /// Signed byte.
  case int8 = "int8_t"
  /// Signed half word.
  case int16 = "int16_t"
  /// Signed world.
  case int32 = "int32_t"
  /// Signed double word.
  case int64 = "int64_t"
  /// Pointer to unsigned byte.
  case uint8Pointer = "uint8_t *"
  /// Pointer to unsigned half word.
  case uint16Pointer = "uint16_t *"
  /// Pointer to unsigned word.
  case uint32Pointer = "uint32_t *"
  /// Pointer to unsigned double word.
  case uint64Pointer = "uint64_t *"
  /// Pointer to signed byte.
  case int8Pointer = "int8_t *"
  /// Pointer to signed half word.
  case int16Pointer = "int16_t *"
  /// Pointer to signed world.
  case int32Pointer = "int32_t *"
  /// Pointer to signed double word.
  case int64Pointer = "int64_t *"
}

extension SVDDataType: XMLNodeInitializable {}
