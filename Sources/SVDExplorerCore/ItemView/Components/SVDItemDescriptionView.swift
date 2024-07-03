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

struct SVDItemDescriptionView: View {
  var title: String
  var text: String

  var body: some View {
    HStack(alignment: .top) {
      Text(self.title)
        .font(.system(.headline, design: .default))
        .foregroundColor(Color(nsColor: .secondaryLabelColor))
        .frame(width: 200, alignment: .trailing)
      Text(self.text)
    }
  }
}
