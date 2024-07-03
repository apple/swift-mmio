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

#if false
import SwiftUI

struct WelcomeWindow: Scene {

    @ObservedObject var settings = Settings.shared

    var body: some Scene {
        Window("Welcome To CodeEdit", id: SceneID.welcome.rawValue) {
            ContentView()
                .frame(width: 740, height: 432)
                .task {
                    if let window = NSApp.findWindow(.welcome) {
                        window.standardWindowButton(.closeButton)?.isHidden = true
                        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                        window.standardWindowButton(.zoomButton)?.isHidden = true
                        window.isMovableByWindowBackground = true
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

    struct ContentView: View {
        @Environment(\.dismiss)
        var dismiss
        @Environment(\.openWindow)
        var openWindow

        var body: some View {
            WelcomeWindowView { url, opened in
                if let url {
                    CodeEditDocumentController.shared.openDocument(withContentsOf: url, display: true) { doc, _, _ in
                        if doc != nil {
                            opened()
                        }
                    }
                } else {
                    dismiss()
                    CodeEditDocumentController.shared.openDocument(
                        onCompletion: { _, _ in opened() },
                        onCancel: { openWindow(sceneID: .welcome) }
                    )
                }
            } newDocument: {
                CodeEditDocumentController.shared.newDocument(nil)
            } dismissWindow: {
                dismiss()
            }
        }
    }
}
#endif
