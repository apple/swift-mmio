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

#pragma once

// These defines are used instead of uintX_t types to avoid a dependency on
// "stdint.h". It is _not_ a safe universal assumption to map these C types to
// specific bit widths, however it should be safe for the platforms that Swift
// currently supports. We expect to replace this module with a Swift language
// primitive for volatile before needing to build for a platform which breaks
// this mapping.
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long int uint64_t;

#define VOLATILE_LOAD(type)                                                    \
__attribute__((always_inline))                                                 \
static type mmio_volatile_load_##type(                                         \
  const volatile type * _Nonnull pointer) { return *pointer; }
VOLATILE_LOAD(uint8_t);
VOLATILE_LOAD(uint16_t);
VOLATILE_LOAD(uint32_t);
VOLATILE_LOAD(uint64_t);

#define VOLATILE_STORE(type)                                                   \
__attribute__((always_inline))                                                 \
static void mmio_volatile_store_##type(                                        \
  volatile type * _Nonnull pointer, type value) { *pointer = value; }
VOLATILE_STORE(uint8_t);
VOLATILE_STORE(uint16_t);
VOLATILE_STORE(uint32_t);
VOLATILE_STORE(uint64_t);
