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

#pragma once

#define XML_GE 0
#define XML_CONTEXT_BYTES 1024

#if defined(__linux__)
#define HAVE_GETRANDOM 1
#else
#define HAVE_ARC4RANDOM_BUF 1
#endif
