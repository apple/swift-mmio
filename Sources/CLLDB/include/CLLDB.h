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
