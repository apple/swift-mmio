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

struct SVDOutlineItemView: View {
  var keyPathComponent: SVDKeyPathComponent

  var body: some View {
    Label(
      self.keyPathComponent.name,
      systemImage: self.keyPathComponent.kind.imageName
    )
    .listItemTint(self.keyPathComponent.kind.imageColor)
  }
}
