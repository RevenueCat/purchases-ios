//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompatibilityNavigationStack.swift
//
//
//  Created by Cody Kerns on 8/15/24.
//

#if os(iOS)

import SwiftUI

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CompatibilityNavigationStack<Content: View>: View {

    @ViewBuilder var content: Content
    let isInNavigationStack: Bool

    init(isInNavigationStack: Bool = false,
         @ViewBuilder content: () -> Content) {
        self.isInNavigationStack = isInNavigationStack
        self.content = content()
    }

    var body: some View {
        if isInNavigationStack {
            content
        } else if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }

}

#endif
