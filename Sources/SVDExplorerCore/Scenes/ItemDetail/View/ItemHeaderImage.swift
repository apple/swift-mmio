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

struct ItemHeaderImage: View {
  var kind: SVDItemKind

  var body: some View {
    Image(systemName: self.kind.imageName)
      .renderingMode(.original)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .foregroundColor(self.kind.imageColor)
      .frame(width: 32, height: 32)
      .padding([.leading, .trailing], 4)
  }
}

#Preview {
  ItemHeaderImage(kind: .device)
  ItemHeaderImage(kind: .peripheral)
  ItemHeaderImage(kind: .cluster)
  ItemHeaderImage(kind: .register)
  ItemHeaderImage(kind: .field)
}
