//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TextComponentViewModel {

    private let localizedStrings: PaywallComponent.LocalizationDictionary
    private let component: PaywallComponent.TextComponent

    let text: String

    init(localizedStrings: PaywallComponent.LocalizationDictionary, component: PaywallComponent.TextComponent) throws {
        self.localizedStrings = localizedStrings
        self.component = component
        self.text = try localizedStrings.string(key: component.text)
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

}

#endif
