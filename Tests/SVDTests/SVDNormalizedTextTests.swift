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

import MMIOUtilities
import XCTest

@testable import SVD

final class SVDNormalizedTextTests: XCTestCase {
  func test_svdNormalizedText_noop() {
    let x = """

      """
  }

  func test_foo() {
    let text = """
      *******************************************************************************\n
      * # License                                                                    \n
      * Copyright 2021 Silicon Laboratories Inc. www.silabs.com                      \n
      *******************************************************************************\n
      *                                                                              \n
      * SPDX-License-Identifier: Zlib                                                \n
      *                                                                              \n
      * The licensor of this software is Silicon Laboratories Inc.                   \n
      *                                                                              \n
      * This software is provided 'as-is', without any express or implied            \n
      * warranty. In no event will the authors be held liable for any damages        \n
      * arising from the use of this software.                                       \n
      *                                                                              \n
      * Permission is granted to anyone to use this software for any purpose,        \n
      * including commercial applications, and to alter it and redistribute it       \n
      * freely, subject to the following restrictions:                               \n
      *                                                                              \n
      * 1. The origin of this software must not be misrepresented; you must not      \n
      *    claim that you wrote the original software. If you use this software      \n
      *    in a product, an acknowledgment in the product documentation would be     \n
      *    appreciated but is not required.                                          \n
      * 2. Altered source versions must be plainly marked as such, and must not be   \n
      *    misrepresented as being the original software.                            \n
      * 3. This notice may not be removed or altered from any source distribution.   \n
      *                                                                              \n
      *******************************************************************************
      """
    let fixed = """
      *******************************************************************************
      * # License
      * Copyright 2021 Silicon Laboratories Inc. www.silabs.com
      *******************************************************************************
      *
      * SPDX-License-Identifier: Zlib
      *
      * The licensor of this software is Silicon Laboratories Inc.
      *
      * This software is provided 'as-is', without any express or implied
      * warranty. In no event will the authors be held liable for any damages
      * arising from the use of this software.
      *
      * Permission is granted to anyone to use this software for any purpose,
      * including commercial applications, and to alter it and redistribute it
      * freely, subject to the following restrictions:
      *
      * 1. The origin of this software must not be misrepresented; you must not
      * claim that you wrote the original software. If you use this software
      * in a product, an acknowledgment in the product documentation would be
      * appreciated but is not required.
      * 2. Altered source versions must be plainly marked as such, and must not be
      * misrepresented as being the original software.
      * 3. This notice may not be removed or altered from any source distribution.
      *
      *******************************************************************************
      """
    XCTAssertEqual(
      fixed,
      text.svdNormalizedText,
      diff(expected: fixed, actual: text.svdNormalizedText, noun: "Formatting"))
  }
}
