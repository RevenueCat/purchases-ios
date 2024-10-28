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

struct LocalizedTextPartial: LocalizedPartial {

    let text: String?
    let partial: PaywallComponent.PartialTextComponent

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
                    try LocalizedTextPartial.create(from: partial, using: localizedStrings)
                }),
                introOffer: try state.introOffer.flatMap({ partial in
                    try LocalizedTextPartial.create(from: partial, using: localizedStrings)
                })
            )
        })

        self.localizedConditions = try self.component.conditions.flatMap({ condition in
            LocalizedConditions(
                mobileLandscape: try condition.mobileLandscape.flatMap({ partial in
                    try LocalizedTextPartial.create(from: partial, using: localizedStrings)
                }),
                tablet: try condition.tablet.flatMap({ partial in
                    try LocalizedTextPartial.create(from: partial, using: localizedStrings)
                }),
                tabletLandscape: try condition.tabletLandscape.flatMap({ partial in
                    try LocalizedTextPartial.create(from: partial, using: localizedStrings)
                }),
                desktop: try condition.desktop.flatMap({ partial in
                    try LocalizedTextPartial.create(from: partial, using: localizedStrings)
                })
            )
        })

    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        application: @escaping (TextComponentStyle) -> some View
    ) -> some View {
        let localalizedPartial = self.buildPartial(state: state, condition: condition)
        let partial = localalizedPartial?.partial

        let style = TextComponentStyle(
            visible: partial?.visible ?? true,
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
        condition: ScreenCondition
    ) -> LocalizedTextPartial? {
        var partial = self.buildConditionPartial(for: condition)

        switch state {
        case .normal:
            break
        case .selected:
            partial = self.combine(partial, with: self.localizedStates?.selected)
        }

        // WIP: Get partial for intro offer
        return partial
    }

    private func buildConditionPartial(
        for conditionType: ScreenCondition
    ) -> LocalizedTextPartial? {

        // Get all conditions to include
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

        // Apply mobile landscape on top of base
        if let mobileLandscape = self.localizedConditions?.mobileLandscape,
           conditionTypesToApply.contains(.mobileLandscape) {
            combinedPartial = combine(combinedPartial, with: mobileLandscape)
        }

        // Apply tablet on top of existing partial
        if let tablet = self.localizedConditions?.tablet,
           conditionTypesToApply.contains(.tablet) {
            combinedPartial = combine(combinedPartial, with: tablet)
        }

        // Apply tablet landscape on top of existin partial
        if let tabletLandscape = self.localizedConditions?.tabletLandscape,
           conditionTypesToApply.contains(.tabletLandscape) {
            combinedPartial = combine(combinedPartial, with: tabletLandscape)
        }

        // Apply desktop on top of existing partial
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
                visible: otherPartial?.visible ?? basePartial?.visible,
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

extension LocalizedTextPartial {

    static func create(
        from partial: PaywallComponent.PartialTextComponent,
        using localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws -> LocalizedTextPartial {
        return LocalizedTextPartial(
            text: try partial.text.flatMap { key in
                try localizedStrings.string(key: key)
            },
            partial: partial
        )
    }

}

extension PaywallComponent.PartialTextComponent {

    var isEmpty: Bool {
        return visible == nil && text == nil && fontFamily == nil && fontWeight == nil && color == nil &&
               backgroundColor == nil && padding == nil && margin == nil &&
               textStyle == nil && horizontalAlignment == nil
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentStyle {

    let visible: Bool
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
        visible: Bool,
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
        self.visible = visible
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
