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

struct ItemDetailSceneData {
  var keyPath: SVDKeyPath
  var register: SVDRegister
}

//extension ItemDetailSceneData: Decodable { }
//
//extension ItemDetailSceneData: Encodable { }
//
//extension ItemDetailSceneData: Equatable { }
//
//extension ItemDetailSceneData: Hashable { }

struct ItemDetailScene: Scene {
  var item: SVDItem

  var body: some Scene {
    WindowGroup("Item Details", id: "item-detail", for: Int.self) { data in
      ItemDetailView(item: item)
        .edgesIgnoringSafeArea(.top)
        .frame(height: 440)
        .toolbar(removing: .title)
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
  }
}
