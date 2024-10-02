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
// swiftlint:disable missing_docs

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class StackComponentViewModel {

    private let locale: Locale
    private let component: PaywallComponent.StackComponent

    let viewModels: [PaywallComponentViewModel]

    init(locale: Locale,
         component: PaywallComponent.StackComponent,
         localizedStrings: PaywallComponent.LocalizationDictionary,
         offering: Offering
    ) throws {
        self.locale = locale
        self.component = component
        self.viewModels = try component.components.map {
            try $0.toViewModel(offering: offering, locale: locale, localizedStrings: localizedStrings)
        }
    }

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
        component.backgroundColor?.toDyanmicColor() ?? Color.clear
    }

    var padding: EdgeInsets {
        component.padding.edgeInsets
    }

    var margin: EdgeInsets {
        component.margin.edgeInsets
    }

    var cornerRadiuses: PaywallComponent.CornerRadiuses {
        component.cornerRadiuses
    }

    var width: PaywallComponent.WidthSize? {
        component.width
    }

}

#endif
