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
    Window("Decoder", id: "decoder") {
      DecoderRootView(register: register)
//        .edgesIgnoringSafeArea(.top)
        .containerBackground(.thickMaterial, for: .window)
        .preferredColorScheme(.dark)
    }
    .windowStyle(.hiddenTitleBar)


    Window("Welcome to SVD Explorer", id: "welcome") {
      WelcomeRootView()
        .edgesIgnoringSafeArea(.top)
        .frame(height: 440)
        .toolbar(removing: .title)
        .gesture(WindowDragGesture())
        .containerBackground(.thinMaterial, for: .window)
        .task {
          // FIXME: Remove Traffic lights
          // there has to be a better way
          NSApp.windows
            .first { $0.identifier?.rawValue == "welcome" }?
            .removeTrafficLights()
        }
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)

    DocumentGroup(newDocument: SVDDocument()) { file in
      SVDDocumentView(document: file.document)
    }

    Window("About SVD Explorer", id: "about") {
      SVDExplorerAboutView()
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .containerBackground(.thickMaterial, for: .window)
        .windowMinimizeBehavior(.disabled)
    }
    .windowResizability(.contentSize)
    .restorationBehavior(.disabled)
  }

  public init() {}
}

