//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PresentationContextModifier.swift
//
//  Created by Rick van der Linden on 10/9/26.

import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PresentationContextModifier: ViewModifier {

    let purchaseHandler: PurchaseHandler

    func body(content: Content) -> some View {
        #if canImport(UIKit) && !os(watchOS)
        content.background {
            PresentationContextReader { window in
                self.purchaseHandler.presentationWindow = window
            }
            .frame(width: 0, height: 0)
        }
        #elseif canImport(AppKit)
        content.background {
            PresentationContextReader { window in
                self.purchaseHandler.presentationWindow = window
            }
            .frame(width: 0, height: 0)
        }
        #else
        content
        #endif
    }

}

#if canImport(UIKit) && !os(watchOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PresentationContextReader: UIViewRepresentable {

    let onWindowChange: @MainActor (UIWindow?) -> Void

    func makeUIView(context: Context) -> WindowReaderView {
        let view = WindowReaderView()
        view.onWindowChange = self.onWindowChange
        return view
    }

    func updateUIView(_ view: WindowReaderView, context: Context) {
        view.onWindowChange = self.onWindowChange
        view.notifyWindowChange()
    }

    @MainActor
    final class WindowReaderView: UIView {

        var onWindowChange: (@MainActor (UIWindow?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            self.notifyWindowChange()
        }

        func notifyWindowChange() {
            self.onWindowChange?(self.window)
        }

    }

}
#elseif canImport(AppKit)
@available(macOS 12.0, *)
private struct PresentationContextReader: NSViewRepresentable {

    let onWindowChange: @MainActor (NSWindow?) -> Void

    func makeNSView(context: Context) -> WindowReaderView {
        let view = WindowReaderView()
        view.onWindowChange = self.onWindowChange
        return view
    }

    func updateNSView(_ view: WindowReaderView, context: Context) {
        view.onWindowChange = self.onWindowChange
        view.notifyWindowChange()
    }

    @MainActor
    final class WindowReaderView: NSView {

        var onWindowChange: (@MainActor (NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            self.notifyWindowChange()
        }

        func notifyWindowChange() {
            self.onWindowChange?(self.window)
        }

    }

}
#endif
