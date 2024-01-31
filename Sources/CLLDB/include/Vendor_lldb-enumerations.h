//===--------------------------------------------------------------*- h -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
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
