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

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

protocol LocalizedPartial {}

struct LocalizedTextPartial: LocalizedPartial {

    let text: String?
    let partial: PaywallComponent.PartialTextComponent

}

struct LocalizedStates<T: LocalizedPartial> {

    let selected: T?
    let introOffer: T?

}

struct LocalizedConditions<T: LocalizedPartial> {

    let mobileLandscape: T?
    let tablet: T?
    let tabletLandscape: T?
    let desktop: T?

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TextComponentViewModel {

    private let localizedStrings: PaywallComponent.LocalizationDictionary
    private let component: PaywallComponent.TextComponent

    private let text: String
    private let localizedStates: LocalizedStates<LocalizedTextPartial>?
    private let localizedConditions: LocalizedConditions<LocalizedTextPartial>?

    init(localizedStrings: PaywallComponent.LocalizationDictionary, component: PaywallComponent.TextComponent) throws {
        self.localizedStrings = localizedStrings
        self.component = component
        self.text = try localizedStrings.string(key: component.text)

        // Localize state partials
        self.localizedStates = try self.component.state.flatMap({ state in
            LocalizedStates(
                selected: try state.selected.flatMap({ partial in
                    LocalizedTextPartial(
                        text: try partial.text.flatMap({ key in
                            try localizedStrings.string(key: key)
                        }),
                        partial: partial
                    )
                }),
                introOffer: try state.introOffer.flatMap({ partial in
                    LocalizedTextPartial(
                        text: try partial.text.flatMap({ key in
                            try localizedStrings.string(key: key)
                        }),
                        partial: partial
                    )
                })
            )
        })

        self.localizedConditions = try self.component.conditions.flatMap({ condition in
            LocalizedConditions(
                mobileLandscape: try condition.mobileLandscape.flatMap({ partial in
                    LocalizedTextPartial(
                        text: try partial.text.flatMap({ key in
                            try localizedStrings.string(key: key)
                        }),
                        partial: partial
                    )
                }),
                tablet: nil,
                tabletLandscape: nil,
                desktop: nil
            )
        })

    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ComponentConditionObserver.ComponentConditionsType,
        application: @escaping (TextComponentStyle) -> some View
    ) -> some View {
        let localalizedPartial = self.buildPartial(state: state, condition: condition)
        let partial = localalizedPartial?.partial

        let style = TextComponentStyle(
            text: localalizedPartial?.text ?? self.text,
            fontFamily: partial?.fontFamily ?? self.component.fontFamily,
            fontWeight: partial?.fontWeight ?? self.component.fontWeight,
            color: partial?.color ?? self.component.color,
            backgroundColor: partial?.backgroundColor ?? self.component.backgroundColor,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            textStyle: partial?.textStyle ?? self.component.textStyle,
            horizontalAlignment: partial?.horizontalAlignment ?? self.component.horizontalAlignment
        )

        application(style)
    }

    func buildPartial(
        state: ComponentViewState,
        condition: ComponentConditionObserver.ComponentConditionsType
    ) -> LocalizedTextPartial? {
        // CONDITIONS
        // Bigger devices overwrite

        // STATE
        // Selected overwrite condidions
        // Intro offer overwrite selecte

        let partialFromConditions = self.buildConditionPartial(for: condition)

        // WIP: Get partial for intro offer
        return self.combine(partialFromConditions, with: self.localizedStates?.selected)
    }

    private func getCurrentCondition() -> PaywallComponent.ComponentConditionsType? {
        #if os(iOS)
        let device = UIDevice.current
        let orientation = UIDevice.current.orientation

        switch (device.userInterfaceIdiom, orientation.isLandscape) {
        case (.pad, true):
            return .tabletLandscape
        case (.pad, false):
            return .tablet
        case (.phone, true):
            return .mobileLandscape
        case (.phone, false):
            return nil
        default:
            return nil
        }
        #elseif os(macOS)
        return .desktop
        #else
        return .mobile
        #endif
    }

    private func buildConditionPartial(
        for conditionType: ComponentConditionObserver.ComponentConditionsType
    ) -> LocalizedTextPartial? {

        let conditionTypesToApply: [PaywallComponent.ComponentConditionsType]
        switch conditionType {
        case .default:
            conditionTypesToApply = []
        case .mobileLandscape:
            conditionTypesToApply = [.mobileLandscape]
        case .tablet:
            conditionTypesToApply = [.mobileLandscape, .tablet]
        case .tabletLandscape:
            conditionTypesToApply = [.mobileLandscape, .tablet, .tabletLandscape]
        case .desktop:
            conditionTypesToApply = [.mobileLandscape, .tablet, .tabletLandscape, .desktop]
        }

        var combinedPartial = LocalizedTextPartial(
            text: nil,
            partial: PaywallComponent.PartialTextComponent()
        )

        // Apply mobile landscape
        if let mobileLandscape = self.localizedConditions?.mobileLandscape,
           conditionTypesToApply.contains(.mobileLandscape) {
            combinedPartial = combine(combinedPartial, with: mobileLandscape)
        }

        // Apply tablet
        if let tablet = self.localizedConditions?.tablet,
           conditionTypesToApply.contains(.tablet) {
            combinedPartial = combine(combinedPartial, with: tablet)
        }

        // Apply tablet landscape
        if let tabletLandscape = self.localizedConditions?.tabletLandscape,
           conditionTypesToApply.contains(.tabletLandscape) {
            combinedPartial = combine(combinedPartial, with: tabletLandscape)
        }

        // Apply desktop
        if let desktop = self.localizedConditions?.desktop,
           conditionTypesToApply.contains(.desktop) {
            combinedPartial = combine(combinedPartial, with: desktop)
        }

        // Return the combined partial if it's not empty, otherwise return nil
        return combinedPartial.partial.isEmpty ? nil : combinedPartial
    }

    private func combine(_ base: LocalizedTextPartial?, with other: LocalizedTextPartial?) -> LocalizedTextPartial {
        let otherPartial = other?.partial
        let basePartial = base?.partial

        return LocalizedTextPartial(
            text: other?.text ?? base?.text,
            partial: PaywallComponent.PartialTextComponent(
                text: otherPartial?.text ?? basePartial?.text,
                fontFamily: otherPartial?.fontFamily ?? basePartial?.fontFamily,
                fontWeight: otherPartial?.fontWeight ?? basePartial?.fontWeight,
                color: otherPartial?.color ?? basePartial?.color,
                backgroundColor: otherPartial?.backgroundColor ?? basePartial?.backgroundColor,
                padding: otherPartial?.padding ?? basePartial?.padding,
                margin: otherPartial?.margin ?? basePartial?.margin,
                textStyle: otherPartial?.textStyle ?? basePartial?.textStyle,
                horizontalAlignment: otherPartial?.horizontalAlignment ?? basePartial?.horizontalAlignment
            )
        )
    }

}

extension PaywallComponent.PartialTextComponent {
    var isEmpty: Bool {
        return text == nil && fontFamily == nil && fontWeight == nil && color == nil &&
               backgroundColor == nil && padding == nil && margin == nil &&
               textStyle == nil && horizontalAlignment == nil
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentStyle {

    let text: String
    let fontFamily: String?
    let fontWeight: Font.Weight
    let color: Color
    let textStyle: Font
    let horizontalAlignment: TextAlignment
    let backgroundColor: Color
    let padding: EdgeInsets
    let margin: EdgeInsets

    init(
        text: PaywallComponent.LocalizationKey,
        fontFamily: String?,
        fontWeight: PaywallComponent.FontWeight,
        color: PaywallComponent.ColorInfo,
        backgroundColor: PaywallComponent.ColorInfo?,
        padding: PaywallComponent.Padding,
        margin: PaywallComponent.Padding,
        textStyle: PaywallComponent.TextStyle,
        horizontalAlignment: PaywallComponent.HorizontalAlignment
    ) {
        self.text = text
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight.fontWeight
        self.color = color.toDyanmicColor()
        self.textStyle = textStyle.font
        self.horizontalAlignment = horizontalAlignment.textAlignment
        self.backgroundColor = backgroundColor?.toDyanmicColor() ?? Color.clear
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
    }

}

#endif
