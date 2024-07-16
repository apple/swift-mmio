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

import SwiftUI

struct SVDDocumentScene: Scene {
  var body: some Scene {
    DocumentGroup(newDocument: SVDDocument()) { file in
      SVDDocumentView(document: file.document)
    }
  }
}
