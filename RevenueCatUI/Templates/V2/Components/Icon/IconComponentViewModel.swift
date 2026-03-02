//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

private typealias PresentedIconPartial = PaywallComponent.PartialIconComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class IconComponentViewModel {

    private let localizationProvider: LocalizationProvider
    let uiConfigProvider: UIConfigProvider
    private let component: PaywallComponent.IconComponent

    private let presentedOverrides: PresentedOverrides<PresentedIconPartial>?

    init(
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        component: PaywallComponent.IconComponent
    ) {
        self.localizationProvider = localizationProvider
        self.uiConfigProvider = uiConfigProvider
        self.component = component

        self.presentedOverrides = self.component.overrides?.toPresentedOverrides { $0 }
    }

    var expectedSize: CGSize {
        let fixedWidth: CGFloat?
        let fixedHeight: CGFloat?

        // Get fixed width (if exists)
        switch self.component.size.width {
        case .fixed(let width):
            fixedWidth = CGFloat(width)
        case .fit, .fill, .relative:
            fixedWidth = nil
        }

        // Get fixed height (if exists)
        switch self.component.size.height {
        case .fixed(let height):
            fixedHeight = CGFloat(height)
        case .fit, .fill, .relative:
            fixedHeight = nil
        }

        let expectedWidth: CGFloat
        let expectedHeight: CGFloat

        switch (fixedWidth, fixedHeight) {
        // We have both
        case let (.some(width), .some(height)):
            expectedWidth = width
            expectedHeight = height
        // Safe enough to assume square icon so set height to width
        case let (.some(width), nil):
            expectedWidth = width
            expectedHeight = width
        // Safe enough to assume square icon so set wdith to height
        case let (nil, .some(height)):
            expectedWidth = height
            expectedHeight = height
        // This should never happen becuase a width or height is required for icon
        case (nil, nil):
            expectedWidth = 32
            expectedHeight = 32
        }

        return CGSize(width: expectedWidth, height: expectedHeight)
    }

    @ViewBuilder
    // swiftlint:disable:next function_parameter_count
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        colorScheme: ColorScheme,
        @ViewBuilder apply: @escaping (IconComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedIconPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )

        let style = IconComponentStyle(
            visible: partial?.visible ?? self.component.visible ?? true,
            baseUrl: partial?.baseUrl ?? self.component.baseUrl,
            formats: partial?.formats ?? self.component.formats,
            size: partial?.size ?? self.component.size,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            color: partial?.color ?? self.component.color,
            iconBackground: partial?.iconBackground ?? self.component.iconBackground,
            uiConfigProvider: uiConfigProvider,
            colorScheme: colorScheme
        )

        apply(style)
    }

}

extension PresentedIconPartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialIconComponent?,
        with other: PaywallComponent.PartialIconComponent?
    ) -> Self {

        let visible = other?.visible ?? base?.visible
        let baseUrl = other?.baseUrl ?? base?.baseUrl
        let iconName = other?.iconName ?? base?.iconName
        let formats = other?.formats ?? base?.formats
        let size = other?.size ?? base?.size
        let padding = other?.padding ?? base?.padding
        let margin = other?.margin ?? base?.margin
        let color = other?.color ?? base?.color
        let iconBackground = other?.iconBackground ?? base?.iconBackground

        return .init(
            visible: visible,
            baseUrl: baseUrl,
            iconName: iconName,
            formats: formats,
            size: size,
            padding: padding,
            margin: margin,
            color: color,
            iconBackground: iconBackground
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IconComponentStyle {

    let visible: Bool
    let url: URL
    let size: PaywallComponent.Size
    let padding: EdgeInsets
    let margin: EdgeInsets
    let color: Color
    let iconBackgroundStyle: BackgroundStyle?
    let iconBackgroundShape: ShapeModifier.Shape?
    let iconBackgroundBorder: ShapeModifier.BorderInfo?
    let iconBackgroundShadow: ShadowModifier.ShadowInfo?

    init(
        visible: Bool = true,
        baseUrl: String,
        formats: PaywallComponent.IconComponent.Formats,
        size: PaywallComponent.Size,
        padding: PaywallComponent.Padding?,
        margin: PaywallComponent.Padding?,
        color: PaywallComponent.ColorScheme,
        iconBackground: PaywallComponent.IconComponent.IconBackground?,
        uiConfigProvider: UIConfigProvider,
        colorScheme: ColorScheme
    ) {
        self.visible = visible
        self.url = URL(string: "\(baseUrl)/\(formats.heic)")!
        self.size = size
        self.padding = (padding ?? .zero).edgeInsets
        self.margin = (margin ?? .zero).edgeInsets
        self.color = color.asDisplayable(uiConfigProvider: uiConfigProvider).toDynamicColor(with: colorScheme)
        self.iconBackgroundStyle = iconBackground?.color
            .asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
        self.iconBackgroundShape = iconBackground?.shape.shape
        self.iconBackgroundBorder = iconBackground?.border?.border(uiConfigProvider: uiConfigProvider)
        self.iconBackgroundShadow = iconBackground?.shadow?
            .shadow(uiConfigProvider: uiConfigProvider, colorScheme: colorScheme)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.IconBackgroundShape {

    var shape: ShapeModifier.Shape {
        switch self {
        case .rectangle(let cornerRadiuses):
            let corners = cornerRadiuses.flatMap { cornerRadiuses in
                ShapeModifier.RadiusInfo(
                    topLeft: cornerRadiuses.topLeading ?? 0,
                    topRight: cornerRadiuses.topTrailing ?? 0,
                    bottomLeft: cornerRadiuses.bottomLeading ?? 0,
                    bottomRight: cornerRadiuses.bottomTrailing ?? 0
                )
            }
            return .rectangle(corners)
        case .circle:
            return .circle
        }
    }

}

#endif
