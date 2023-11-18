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

/// A marker error used as an early exit for a failed macro expansion.
///
/// Expansion errors should not be directly created, instead calls to
/// ``MacroContext.error`` will return an expansion error which can be thrown
/// to early exit.
struct ExpansionError: Error {}
