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
class StackComponentViewModel {

    private let component: PaywallComponent.StackComponent

    let viewModels: [PaywallComponentViewModel]

    init(component: PaywallComponent.StackComponent,
         localizedStrings: PaywallComponent.LocalizationDictionary,
         offering: Offering
    ) throws {
        self.component = component
        self.viewModels = try component.components.map {
            try $0.toViewModel(offering: offering, localizedStrings: localizedStrings)
        }
    }

    var dimension: PaywallComponent.Dimension {
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

    var width: PaywallComponent.WidthSize? {
        component.width
    }

    var cornerRadiuses: CornerBorderModifier.RaidusInfo? {
        component.cornerRadiuses.flatMap { cornerRadiuses in
            CornerBorderModifier.RaidusInfo(
                topLeft: cornerRadiuses.topLeading,
                topRight: cornerRadiuses.topTrailing,
                bottomLeft: cornerRadiuses.bottomLeading,
                bottomRight: cornerRadiuses.bottomLeading
            )
        }
    }

    var border: CornerBorderModifier.BorderInfo? {
        component.border.flatMap { border in
            CornerBorderModifier.BorderInfo(
                color: border.color.toDyanmicColor(),
                width: border.width
            )
        }
    }

}

#endif
