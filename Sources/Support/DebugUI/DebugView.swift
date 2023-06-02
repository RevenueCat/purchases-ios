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

#if DEBUG && os(iOS)

import SwiftUI

@available(iOS 16.0, *)
public extension View {

    /// Adds a bottom sheet overlay to the current view which allows debugging the current setup
    /// of ``Offerings`` and ``StoreProduct``s.
    func debugRevenueCatOverlay() -> some View {
        self.bottomSheet(
            presentationDetents: [
                .fraction(0.2),
                .fraction(0.6),
                .large
            ],
            isPresented: .constant(true),
            cornerRadius: 10,
            transparentBackground: true,
            content: {
                DebugSwiftUIRootView()
            }
        )
    }

}

#endif
