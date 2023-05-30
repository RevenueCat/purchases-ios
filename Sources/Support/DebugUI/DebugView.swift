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

#if DEBUG && canImport(SwiftUI) && !os(macOS)

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
public extension View {

    // TODO: document
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
