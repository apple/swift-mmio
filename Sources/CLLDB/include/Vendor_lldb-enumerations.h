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

namespace lldb {

enum ErrorType {
  eErrorTypeInvalid,
  eErrorTypeGeneric,    ///< Generic errors that can be any value.
  eErrorTypeMachKernel, ///< Mach kernel error codes.
  eErrorTypePOSIX,      ///< POSIX error codes.
  eErrorTypeExpression, ///< These are from the ExpressionResults enum.
  eErrorTypeWin32       ///< Standard Win32 error codes.
};

} // namespace lldb
