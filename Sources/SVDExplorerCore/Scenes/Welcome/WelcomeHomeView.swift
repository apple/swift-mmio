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

import AppKit
import SwiftUI

struct WelcomeHomeView: View {
  var body: some View {
    ZStack(alignment: .topLeading) {
      VStack {
        Spacer()

        Image.applicationIcon
          .resizable()
          .frame(width: 128, height: 128)

        Text("SVD Explorer")
          .font(.largeTitle)
          .fontWeight(.semibold)

        Text("Version 0.1.0")
          .font(.headline)
          .fontWeight(.light)

        Spacer()

        HStack {
          Spacer()
        }
      }
      WelcomeCloseButtonView()
    }
    .background(.background)
  }
}
