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
        .frame(alignment: .trailing)
        .alignmentGuide(.descriptionTitleAlignment) { $0[.trailing] }
      Text(self.text)
    }
  }
}

#Preview {
  SVDItemDescriptionView(title: "Hello", text: "World")
}

extension HorizontalAlignment {
  private enum DescriptionTitleAlignment: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat { d[.leading] }
  }
  static let descriptionTitleAlignment = HorizontalAlignment(DescriptionTitleAlignment.self)
}
