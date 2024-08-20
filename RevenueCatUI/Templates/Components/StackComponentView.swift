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
    var dimension: PaywallComponent.StackComponent.Dimension {
        component.dimension
    }
    var components: [PaywallComponent] {
        component.components
    }

    var spacing: CGFloat? {
        component.spacing
    }

    var backgroundColor: Color {
        component.backgroundPaywallColor?.underlyingColor ?? Color.clear
    }

    let locale: Locale
    let configuration: TemplateViewConfiguration

    var body: some View {
        switch self.dimension {
        case .vertical:
            VStack(spacing: spacing) {
                ComponentsView(locale: locale, components: components, configuration: configuration)
            }
            .background(backgroundColor)
        case .horizontal:
            HStack(spacing: spacing) {
                ComponentsView(locale: locale, components: components, configuration: configuration)
            }
            .background(backgroundColor)
        case .zlayer:
            ZStack {
                ComponentsView(locale: locale, components: components, configuration: configuration)
            }
            .background(backgroundColor)
        }
    }

    init(component: PaywallComponent.StackComponent, locale: Locale, configuration: TemplateViewConfiguration) {
        self.component = component
        self.locale = locale
        self.configuration = configuration
    }
}

#endif
