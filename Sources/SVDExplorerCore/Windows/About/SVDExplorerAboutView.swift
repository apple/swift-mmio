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

struct SVDExplorerAboutView: View {
  @Environment(\.openURL) var openURL

  var body: some View {
    HStack(spacing: 20) {
      Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .frame(width: 128, height: 128)
        .padding([.top, .leading, .bottom], 40)
      VStack(alignment: .leading) {
        Text("SVD Explorer")
          .font(.largeTitle)
          .fontWeight(.semibold)
        
        Text("Version 0.1.0")
          .font(.headline)
          .fontWeight(.light)

        Spacer()

        Text("""
          Copyright (c) 2024 Apple Inc. and the Swift project authors
          Licensed under Apache License v2.0 with Runtime Library Exception
          """)
          .font(.caption2)
          .fontWeight(.light)
          .frame(maxWidth: 300, alignment: .leading)

        Spacer()

        HStack {
          Spacer()
          Button("License") {
            self.openURL(URL(string: "https://swift.org/LICENSE.txt")!)
          }
          .buttonStyle(.borderedProminent)
        }
      }
      .padding()
    }
    .fixedSize()
  }
}
