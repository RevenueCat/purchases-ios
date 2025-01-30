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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TextComponentViewModel {

    private let localizationProvider: LocalizationProvider
    let uiConfigProvider: UIConfigProvider
    private let component: PaywallComponent.TextComponent

    private let text: String
    private let presentedOverrides: PresentedOverrides<LocalizedTextPartial>?

    init(
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        component: PaywallComponent.TextComponent
    ) throws {
        self.localizationProvider = localizationProvider
        self.uiConfigProvider = uiConfigProvider
        self.component = component
        self.text = try localizationProvider.localizedStrings.string(key: component.text)

        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides {
            try LocalizedTextPartial.create(from: $0, using: localizationProvider.localizedStrings)
        }

    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        packageContext: PackageContext,
        isEligibleForIntroOffer: Bool,
        apply: @escaping (TextComponentStyle) -> some View
    ) -> some View {
        let localizedPartial = LocalizedTextPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: self.presentedOverrides
        )
        let partial = localizedPartial?.partial
        let text = localizedPartial?.text ?? self.text

        let fontFamily = self.uiConfigProvider.getFontFamily(for: partial?.fontName ?? self.component.fontName)

        let style = TextComponentStyle(
            uiConfigProvider: self.uiConfigProvider,
            visible: partial?.visible ?? true,
            text: Self.processText(
                text,
                packageContext: packageContext,
                variableConfig: uiConfigProvider.variableConfig,
                locale: self.localizationProvider.locale,
                localizations: self.uiConfigProvider.getLocalizations(for: self.localizationProvider.locale)
            ),
            fontFamily: fontFamily,
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

    private static func processText(_ text: String,
                                    packageContext: PackageContext,
                                    variableConfig: UIConfig.VariableConfig,
                                    locale: Locale,
                                    localizations: [String: String]) -> String {
        let processedWithV2 = Self.processTextV2(
            text,
            packageContext: packageContext,
            variableConfig: variableConfig,
            locale: locale,
            localizations: localizations
        )
        // Note: This is temporary while in closed beta and shortly after
        let processedWithV2AndV1 = Self.processTextV1(
            processedWithV2,
            packageContext: packageContext,
            locale: locale
        )

        return processedWithV2AndV1
    }

    private static func processTextV2(_ text: String,
                                      packageContext: PackageContext,
                                      variableConfig: UIConfig.VariableConfig,
                                      locale: Locale,
                                      localizations: [String: String]) -> String {
        guard let package = packageContext.package else {
            return text
        }

        let discount = Self.discount(
            from: package.storeProduct.pricePerMonth?.doubleValue,
            relativeTo: packageContext.variableContext.mostExpensivePricePerMonth
        )

        let handler = VariableHandlerV2(
            variableCompatibilityMap: variableConfig.variableCompatibilityMap,
            functionCompatibilityMap: variableConfig.functionCompatibilityMap,
            discountRelativeToMostExpensivePerMonth: discount,
            showZeroDecimalPlacePrices: packageContext.variableContext.showZeroDecimalPlacePrices
        )

        return handler.processVariables(
            in: text,
            with: package,
            locale: locale,
            localizations: localizations
        )
    }

    private static func processTextV1(_ text: String,
                                      packageContext: PackageContext,
                                      locale: Locale) -> String {
        guard let package = packageContext.package else {
            return text
        }

        let discount = Self.discount(
            from: package.storeProduct.pricePerMonth?.doubleValue,
            relativeTo: packageContext.variableContext.mostExpensivePricePerMonth
        )

        let context: VariableHandler.Context = .init(
            discountRelativeToMostExpensivePerMonth: discount,
            showZeroDecimalPlacePrices: packageContext.variableContext.showZeroDecimalPlacePrices
        )

        return VariableHandler.processVariables(
            in: text,
            with: package,
            context: context,
            locale: locale
        )
    }

    private static func discount(from pricePerMonth: Double?, relativeTo mostExpensive: Double?) -> Double? {
        guard let pricePerMonth, let mostExpensive else { return nil }
        guard pricePerMonth < mostExpensive else { return nil }

        return (mostExpensive - pricePerMonth) / mostExpensive
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
    let color: DisplayableColorScheme
    let font: Font
    let horizontalAlignment: Alignment
    let textAlignment: TextAlignment
    let backgroundStyle: BackgroundStyle?
    let size: PaywallComponent.Size
    let padding: EdgeInsets
    let margin: EdgeInsets

    init(
        uiConfigProvider: UIConfigProvider,
        visible: Bool,
        text: String,
        fontFamily: String?,
        fontWeight: PaywallComponent.FontWeight,
        color: PaywallComponent.ColorScheme,
        backgroundColor: PaywallComponent.ColorScheme?,
        size: PaywallComponent.Size,
        padding: PaywallComponent.Padding,
        margin: PaywallComponent.Padding,
        fontSize: CGFloat,
        horizontalAlignment: PaywallComponent.HorizontalAlignment
    ) {
        self.visible = visible
        self.text = text
        self.fontWeight = fontWeight.fontWeight
        self.color = color.asDisplayable(uiConfigProvider: uiConfigProvider)

        // WIP: Take into account the fontFamily mapping
        self.font = Self.makeFont(size: fontSize, familyName: fontFamily)

        self.textAlignment = horizontalAlignment.textAlignment
        self.horizontalAlignment = horizontalAlignment.frameAlignment
        self.backgroundStyle = backgroundColor?.asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
        self.size = size
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TextComponentStyle {

    static func makeFont(size fontSize: CGFloat, familyName: String?) -> Font {
        // Create the base font, with fallback to the system font
        let baseFont: UIFont
        if let familyName = familyName {
            if let customFont = UIFont(name: familyName, size: fontSize) {
                baseFont = customFont
            } else {
                Logger.warning("Custom font '\(familyName)' could not be loaded. Falling back to system font.")
                baseFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            }
        } else {
            baseFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        }

        // Apply dynamic type scaling
        let uiFont = UIFontMetrics.default.scaledFont(for: baseFont)
        return Font(uiFont)
    }

}

#endif
