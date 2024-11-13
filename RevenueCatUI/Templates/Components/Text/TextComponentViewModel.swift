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

    private let text: String
    private let presentedOverrides: PresentedOverrides<LocalizedTextPartial>?

    init(localizedStrings: PaywallComponent.LocalizationDictionary, component: PaywallComponent.TextComponent) throws {
        self.localizedStrings = localizedStrings
        self.component = component
        self.text = try localizedStrings.string(key: component.text)

        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides {
            try LocalizedTextPartial.create(from: $0, using: localizedStrings)
        }

    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        apply: @escaping (TextComponentStyle) -> some View
    ) -> some View {
        let localizedPartial = LocalizedTextPartial.buildPartial(
            state: state,
            condition: condition,
            with: self.presentedOverrides
        )
        let partial = localizedPartial?.partial

        let style = TextComponentStyle(
            visible: partial?.visible ?? true,
            text: localizedPartial?.text ?? self.text,
            fontFamily: partial?.fontName ?? self.component.fontName,
            fontWeight: partial?.fontWeight ?? self.component.fontWeight,
            color: partial?.color ?? self.component.color,
            backgroundColor: partial?.backgroundColor ?? self.component.backgroundColor,
            size: partial?.size ?? self.component.size,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            fontSize: partial?.fontSize ?? self.component.fontSize,
            horizontalAlignment: partial?.horizontalAlignment ?? self.component.horizontalAlignment
        )

        apply(style)
    }

}

struct LocalizedTextPartial: PresentedPartial {

    let text: String?
    let partial: PaywallComponent.PartialTextComponent

    static func combine(_ base: LocalizedTextPartial?, with other: LocalizedTextPartial?) -> LocalizedTextPartial {
        let otherPartial = other?.partial
        let basePartial = base?.partial

        return LocalizedTextPartial(
            text: other?.text ?? base?.text,
            partial: PaywallComponent.PartialTextComponent(
                visible: otherPartial?.visible ?? basePartial?.visible,
                text: otherPartial?.text ?? basePartial?.text,
                fontName: otherPartial?.fontName ?? basePartial?.fontName,
                fontWeight: otherPartial?.fontWeight ?? basePartial?.fontWeight,
                color: otherPartial?.color ?? basePartial?.color,
                backgroundColor: otherPartial?.backgroundColor ?? basePartial?.backgroundColor,
                padding: otherPartial?.padding ?? basePartial?.padding,
                margin: otherPartial?.margin ?? basePartial?.margin,
                fontSize: otherPartial?.fontSize ?? basePartial?.fontSize,
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentStyle {

    let visible: Bool
    let text: String
    let fontWeight: Font.Weight
    let color: Color
    let fontSize: Font
    let horizontalAlignment: TextAlignment
    let backgroundColor: Color
    let size: PaywallComponent.Size
    let padding: EdgeInsets
    let margin: EdgeInsets

    init(
        visible: Bool,
        text: String,
        fontFamily: String?,
        fontWeight: PaywallComponent.FontWeight,
        color: PaywallComponent.ColorScheme,
        backgroundColor: PaywallComponent.ColorScheme?,
        size: PaywallComponent.Size,
        padding: PaywallComponent.Padding,
        margin: PaywallComponent.Padding,
        fontSize: PaywallComponent.FontSize,
        horizontalAlignment: PaywallComponent.HorizontalAlignment
    ) {
        self.visible = visible
        self.text = text
        self.fontWeight = fontWeight.fontWeight
        self.color = color.toDynamicColor()

        // WIP: Take into account the fontFamily mapping
        self.fontSize = fontSize.font

        self.horizontalAlignment = horizontalAlignment.textAlignment
        self.backgroundColor = backgroundColor?.toDynamicColor() ?? Color.clear
        self.size = size
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
    }

}

#endif
