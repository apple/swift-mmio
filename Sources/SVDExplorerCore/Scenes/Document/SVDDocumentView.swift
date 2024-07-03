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

struct SVDDocumentView: View {
  var document: SVDDocument
  @State var sortOrder = 0
  @State var selection: Set<SVDKeyPath>

  init(document: SVDDocument) {
    self.document = document
    self.selection = [
      .init(components: [.init(kind: .device, name: document.device.name)])
    ]
  }

  var body: some View {
    NavigationSplitView {
      //      Text("Sort Order")
      //        .font(.system(.headline, design: .default))
      //        .foregroundColor(Color(nsColor: .secondaryLabelColor))
      //      Picker("", selection: $sortOrder) {
      //        Text("Address").tag(0)
      //        Text("Name").tag(1)
      //      }
      //      .padding([.leading, .trailing])
      //      .pickerStyle(.segmented)
      //      Divider()
      let item = SVDOutlineItem(device: self.document.device, keyPath: .empty)
      SVDOutlineListView(root: item, selection: self.$selection)
        .frame(minWidth: 200)
    } detail: {
      List {
        ForEach(Array(self.selection).sorted()) { (keyPath: SVDKeyPath) in
          if let item = try? self.document.item(at: keyPath) {
            Section {
              SVDItemView(keyPath: keyPath, item: item)
            } header: {
              SVDBreadCrumbView(keyPath: keyPath)
            }
          } else {
            EmptyView()
          }
        }
      }
      .listStyle(.plain)
      .frame(minWidth: 400)
    }
    .frame(minHeight: 400)
  }
}
