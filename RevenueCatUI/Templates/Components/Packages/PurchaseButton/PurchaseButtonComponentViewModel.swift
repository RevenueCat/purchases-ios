//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseButtonComponentViewModel.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PurchaseButtonComponentViewModel {

    private let localizedStrings: PaywallComponent.LocalizationDictionary
    private let component: PaywallComponent.PurchaseButtonComponent

    let cta: String
    let ctaIntroOffer: String?

    init(localizedStrings: PaywallComponent.LocalizationDictionary,
         component: PaywallComponent.PurchaseButtonComponent) throws {
        self.localizedStrings = localizedStrings
        self.component = component

        self.cta = try localizedStrings.string(key: component.cta)
        self.ctaIntroOffer = try component.ctaIntroOffer.flatMap {
            try localizedStrings.string(key: $0)
        }
    }

    var fontFamily: String? {
        component.fontFamily
    }

    var fontWeight: Font.Weight {
        component.fontWeight.fontWeight
    }

    var color: Color {
        component.color.toDyanmicColor()
    }

    var textStyle: Font {
        component.textStyle.font
    }

    var horizontalAlignment: TextAlignment {
        component.horizontalAlignment.textAlignment
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

    var clipShape: PaywallComponent.Shape {
        component.shape
    }

    var cornerRadiuses: PaywallComponent.CornerRadiuses? {
        component.cornerRadiuses
    }

}

#endif
