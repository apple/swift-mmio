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
import SVD

public struct SVDExplorerApp: App {
  public var body: some Scene {
//    DocumentGroup(newDocument: SVDDocument()) { file in
//      SVDDocumentView(document: file.document)
//    }
//
    Window("About SVD Explorer", id: "about") {
      AboutView()
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .containerBackground(.thickMaterial, for: .window)
        .windowMinimizeBehavior(.disabled)
    }
    .windowResizability(.contentSize)
//    .restorationBehavior(.disabled)
  }

  public init() {}
}

struct AboutView: View {
  var body: some View {
    HStack {
      Image("Foo")
        .resizable()
        .frame(width: 120, height: 120)
        .aspectRatio(1, contentMode: .fit)
        .padding(40)
      VStack(alignment: .leading) {
        Text("SVD Explorer")
          .font(.largeTitle)
        Text("Version 0.1.0")
          .font(.callout)
        Spacer()

        Text("""
          Copyright (c) 2023 Apple Inc. and the Swift project authors
          Licensed under Apache License v2.0 with Runtime Library Exception
          """)
          .font(.caption)

        HStack {
          Spacer()
          Link("License", destination: URL(string: "https://swift.org/LICENSE.txt")!)
          Button("Close") {
      
          }
        }
      }
    }
    .frame(width: 500, height: 180)
  }
}
