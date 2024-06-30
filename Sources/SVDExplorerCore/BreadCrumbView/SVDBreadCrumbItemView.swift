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

struct SVDBreadCrumbItemView: View {
  @State var isHovered: Bool = false

  var keyPathComponent: SVDKeyPathComponent
  var isLast: Bool

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: self.keyPathComponent.kind.imageName)
        .renderingMode(.original)
        .foregroundColor(self.keyPathComponent.kind.imageColor)
      Text(self.keyPathComponent.name)
        .font(.system(.callout, design: .monospaced))
      if self.isHovered {
        Image(systemName: "chevron.up.chevron.down")
          .frame(width: 8)
          .imageScale(.small)
      } else if !self.isLast {
        Image(systemName: "chevron.compact.right")
          .frame(width: 8)
      }
    }
    .padding(4)
    .background(
      self.isHovered ? Color(nsColor: .tertiarySystemFill) : Color.clear,
      in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    .onHover { self.isHovered = $0 }
  }
}

#Preview {
  SVDBreadCrumbItemView(keyPathComponent: .device("Foo"), isLast: false)
    .frame(minWidth: 200, minHeight: 80)
}
