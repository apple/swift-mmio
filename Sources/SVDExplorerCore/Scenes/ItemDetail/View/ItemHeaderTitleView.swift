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

struct SVDHeaderTitleView: View {
  var alignment: HorizontalAlignment
  var title: String
  var text: String

  var body: some View {
    VStack(alignment: self.alignment, spacing: 0) {
      Text(self.title)
        .foregroundStyle(.secondary)
      Text(self.text)
        .font(.system(.title2, design: .monospaced))
    }
  }
}

#Preview {
  SVDHeaderTitleView(
    alignment: .leading,
    title: "Some Title",
    text: "Some Text"
  )
  .frame(width: 100, height: 40)
}
