//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ScrollViewWithOSBackground.swift
//
//  Created by Facundo Menzella on 15/5/25.

import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ScrollViewWithOSBackground<Content: View>: View {
    @Environment(\.colorScheme)
    private var colorScheme

    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color(colorScheme == .light ? UIColor.secondarySystemBackground : UIColor.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                content()
            }
            .scrollBounceBehaviorBasedOnSize()
        }
    }
}

#endif
