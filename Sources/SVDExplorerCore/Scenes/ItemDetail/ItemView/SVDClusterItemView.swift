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

struct SVDClusterItemView: View {
  var cluster: SVDCluster

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ItemHeaderImage(kind: .cluster)
        SVDHeaderTitleView(
          alignment: .leading,
          title: SVDItemKind.cluster.displayName,
          text: self.cluster.name)
      }
      ItemDescriptionView(description: self.cluster.description)
      Grid {
        ItemRegisterPropertiesView(model: self.cluster.registerProperties)
      }
    }
  }
}
