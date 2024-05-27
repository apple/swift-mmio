//===--------------------------------------------------------------*- h -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#pragma once

#if __has_include(<LLDB/LLDB.h>)
#include <LLDB/LLDB.h>
#else
#include "Vendor_SBCommandInterpreter.h"
#include "Vendor_SBCommandReturnObject.h"
#include "Vendor_SBDebugger.h"
#include "Vendor_SBError.h"
#include "Vendor_SBProcess.h"
#include "Vendor_SBTarget.h"
#endif

#include "SBSwift.h"
