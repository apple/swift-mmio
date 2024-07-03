//
//  SVDOutlineListView.swift
//  SVDExplorer
//
//  Created by Rauhul Varma on 1/30/24.
//

import SwiftUI

struct SVDOutlineListView: View {
  var root: SVDOutlineItem
  @Binding var selection: Set<SVDKeyPath>

  var body: some View {
    List(selection: self.$selection) {
      let roots = [self.root]
      OutlineGroup(roots, children: \.children) {
        SVDOutlineItemView(keyPathComponent: $0.keyPath.components.last!)
      }
    }
  }
}
