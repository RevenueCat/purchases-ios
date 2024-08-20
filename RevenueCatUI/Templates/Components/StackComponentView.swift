//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponentView.swift
//
//  Created by James Borthwick on 2024-08-20.

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StackComponentView: View {

    let component: PaywallComponent.StackComponent
    let components: [PaywallComponent]
    let layoutComponents: ([PaywallComponent]) -> AnyView

    var body: some View {
        VStack {
            layoutComponents(components)
        }
    }

    init(component: PaywallComponent.StackComponent,
         layoutComponents: @escaping ([PaywallComponent]) -> AnyView) {
        self.component = component
        self.components = component.components
        self.layoutComponents = layoutComponents
    }
}

#endif
