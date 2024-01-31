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

struct NoSVDLoadedError {}

extension NoSVDLoadedError: CustomStringConvertible {
  var description: String {
    """
    No svd loaded, please run `\(LoadCommand.usageString())` before \
    running other commands.
    """
  }
}

extension NoSVDLoadedError: Error {}
