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
// swiftlint:disable missing_docs

import Combine
import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class TextComponentViewModel: ObservableObject {

    let locale: Locale
    let localizedStrings: LocalizationDictionary
    @Published private(set) var component: PaywallComponent.TextComponent

    init(locale: Locale, localizedStrings: LocalizationDictionary, component: PaywallComponent.TextComponent) throws {
        try component.validateLocalizationIDs(using: localizedStrings)
        self.locale = locale
        self.localizedStrings = localizedStrings
        self.component = component
    }

    var text: String {
        // TODO: Replace variables like "{{ }}"
        // TODO: Add logs?
        if let textLid = component.textLid {
            if let localizedText = localizedStrings[textLid] {
                return localizedText
            } else {
                return component.text.value.first?.value as? String ?? "missing localized text for \(textLid)"
            }
        } else {
            return component.text.value.first?.value as? String ?? "missing localized text"
        }
    }

    public var fontFamily: String {
        component.fontFamily
    }

    public var fontWeight: Font.Weight {
        component.fontWeight.fontWeight
    }

    public var color: Color {
        component.color.toDyanmicColor()
    }

    public var textStyle: Font {
        component.textStyle.font
    }

    public var horizontalAlignment: TextAlignment {
        component.horizontalAlignment.textAlignment
    }

    public var backgroundColor: Color {
        component.backgroundColor?.toDyanmicColor() ?? Color.clear
    }

    public var padding: EdgeInsets {
        component.padding.edgeInsets
    }

}
#endif
