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

import SVD
import SwiftUI

struct ItemDescriptionView: View {
  var description: String?

  var body: some View {
    if let description = self.description {
      Text("Description")
        .foregroundStyle(.secondary)
      Text(description.svdNormalizedText)
      Divider()
    }
  }
}
