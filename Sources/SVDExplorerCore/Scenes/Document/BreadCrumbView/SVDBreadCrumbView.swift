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

struct SVDBreadCrumbView: View {
  @State var keyPath: SVDKeyPath

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 0) {
        ForEach(Array(self.keyPath.components.enumerated()), id: \.element) {
          SVDBreadCrumbItemView(
            keyPathComponent: $1,
            isLast: $0 == self.keyPath.components.count - 1)
        }
      }
    }
    .scrollIndicators(.never)
  }
}

#Preview {
  SVDBreadCrumbView(
    keyPath: .init(components: [
      .device("Some Device"),
      .peripheral("Some Peripheral"),
      .cluster("Some Cluster"),
      .cluster("Some Cluster2"),
      .register("Some Register"),
      .field("Some Field"),
    ])
  )
  .frame(minWidth: 200, minHeight: 80)
}
