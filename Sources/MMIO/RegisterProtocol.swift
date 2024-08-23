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

// This only exists because RegisterBlock is not a concrete type, ideally
// RegisterBlock and Register would both be the same Register type
public protocol RegisterProtocol {
  #if FEATURE_INTERPOSABLE
  init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?)
  #else
  init(unsafeAddress: UInt)
  #endif
}
