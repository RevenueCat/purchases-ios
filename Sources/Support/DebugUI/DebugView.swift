//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DebugView.swift
//
//  Created by Nacho Soto on 5/30/23.

#if DEBUG && os(iOS) && swift(>=5.8)

import SwiftUI

@available(iOS 16.0, *)
public extension View {

    /// Adds a bottom sheet overlay to the current view which allows debugging the current SDK setup.
    ///
    /// Usage:
    /// ```swift
    ///  var body: some View {
    ///    YourViewContent()
    ///      .debugRevenueCatOverlay()
    ///  }
    /// ```
    ///
    /// - Note: This will present the overlay automatically on launch.
    /// To manage the presentation manually, use `debugRevenueCatOverlay(isPresented:)`
    func debugRevenueCatOverlay() -> some View {
        return self.debugRevenueCatOverlay(isPresented: .constant(true))
    }

    /// Adds a bottom sheet overlay to the current view which allows debugging the current SDK setup.
    ///
    /// Usage:
    /// ```swift
    /// @State private var debugOverlayVisible: Bool = false
    ///
    /// var body: some View {
    ///    YourViewContent()
    ///      .debugRevenueCatOverlay(isPresented: self.debugOverlayVisible)
    ///
    ///    Button {
    ///      self.debugOverlayVisible.toggle()
    ///    } label: {
    ///      Text("RevenueCat Debug view")
    ///    }
    /// }
    /// ```
    func debugRevenueCatOverlay(isPresented: Binding<Bool>) -> some View {
        self.bottomSheet(
            presentationDetents: [
                .fraction(0.2),
                .fraction(0.6),
                .large
            ],
            isPresented: isPresented,
            largestUndimmedIdentifier: .fraction(0.6),
            cornerRadius: DebugSwiftUIRootView.cornerRadius,
            content: {
                DebugSwiftUIRootView()
            }
        )
    }

}

#endif
