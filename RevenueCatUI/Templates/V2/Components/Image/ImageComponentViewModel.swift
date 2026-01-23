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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ImageComponentViewModel {

    private let localizationProvider: LocalizationProvider
    let uiConfigProvider: UIConfigProvider
    private let component: PaywallComponent.ImageComponent

    private let imageInfo: PaywallComponent.ThemeImageUrls
    private let presentedOverrides: PresentedOverrides<LocalizedImagePartial>?

    init(
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        component: PaywallComponent.ImageComponent
    ) throws {
        self.localizationProvider = localizationProvider
        self.uiConfigProvider = uiConfigProvider
        self.component = component

        if let overrideSourceLid = component.overrideSourceLid {
            self.imageInfo = try localizationProvider.localizedStrings.image(key: overrideSourceLid)
        } else {
            self.imageInfo = component.source
        }

        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides {
            try LocalizedImagePartial.create(from: $0, using: localizationProvider.localizedStrings)
        }
    }

    @ViewBuilder
    // swiftlint:disable:next function_parameter_count
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        colorScheme: ColorScheme,
        @ViewBuilder apply: @escaping (ImageComponentStyle) -> some View
    ) -> some View {
        let localizedPartial = LocalizedImagePartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )
        let partial = localizedPartial?.partial

        let style = ImageComponentStyle(
            visible: partial?.visible ?? self.component.visible ?? true,
            source: localizedPartial?.imageInfo ?? self.imageInfo,
            size: partial?.size ?? self.component.size,
            fitMode: partial?.fitMode ?? self.component.fitMode,
            maskShape: partial?.maskShape ?? self.component.maskShape,
            colorOverlay: partial?.colorOverlay ?? self.component.colorOverlay,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            border: partial?.border ?? self.component.border,
            shadow: partial?.shadow ?? self.component.shadow,
            uiConfigProvider: self.uiConfigProvider,
            colorScheme: colorScheme
        )

        apply(style)
    }

}

struct LocalizedImagePartial: PresentedPartial {

    let imageInfo: PaywallComponent.ThemeImageUrls?
    let partial: PaywallComponent.PartialImageComponent

    static func combine(_ base: Self?, with other: Self?) -> Self {
        let otherPartial = other?.partial
        let basePartial = base?.partial

        return Self(
            imageInfo: other?.imageInfo ?? base?.imageInfo,
            partial: PaywallComponent.PartialImageComponent(
                visible: otherPartial?.visible ?? basePartial?.visible,
                source: otherPartial?.source ?? basePartial?.source,
                size: otherPartial?.size ?? basePartial?.size,
                overrideSourceLid: otherPartial?.overrideSourceLid ?? basePartial?.overrideSourceLid,
                fitMode: otherPartial?.fitMode ?? basePartial?.fitMode,
                maskShape: otherPartial?.maskShape ?? basePartial?.maskShape,
                colorOverlay: otherPartial?.colorOverlay ?? basePartial?.colorOverlay,
                padding: otherPartial?.padding ?? basePartial?.padding,
                margin: otherPartial?.margin ?? basePartial?.margin,
                border: otherPartial?.border ?? basePartial?.border,
                shadow: otherPartial?.shadow ?? basePartial?.shadow
            )
        )
    }

}

extension LocalizedImagePartial {

    static func create(
        from partial: PaywallComponent.PartialImageComponent,
        using localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws -> LocalizedImagePartial {
        return LocalizedImagePartial(
            imageInfo: try partial.overrideSourceLid.flatMap { key in
                try localizedStrings.image(key: key)
            } ?? partial.source,
            partial: partial
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ImageComponentStyle {

    let visible: Bool
    let widthLight: Int
    let heightLight: Int
    let widthDark: Int?
    let heightDark: Int?
    let url: URL
    let lowResUrl: URL?
    let darkUrl: URL?
    let darkLowResUrl: URL?
    let size: PaywallComponent.Size
    let shape: ShapeModifier.Shape?
    let colorOverlay: DisplayableColorScheme?
    let padding: EdgeInsets
    let margin: EdgeInsets
    let border: ShapeModifier.BorderInfo?
    let shadow: ShadowModifier.ShadowInfo?
    let contentMode: ContentMode

    init(
        visible: Bool = true,
        source: PaywallComponent.ThemeImageUrls,
        size: PaywallComponent.Size,
        fitMode: PaywallComponent.FitMode,
        maskShape: PaywallComponent.MaskShape? = nil,
        colorOverlay: PaywallComponent.ColorScheme? = nil,
        padding: PaywallComponent.Padding? = nil,
        margin: PaywallComponent.Padding? = nil,
        border: PaywallComponent.Border? = nil,
        shadow: PaywallComponent.Shadow? = nil,
        uiConfigProvider: UIConfigProvider,
        colorScheme: ColorScheme
    ) {
        self.visible = visible
        self.widthLight = source.light.width
        self.heightLight = source.light.height
        self.widthDark = source.dark?.width
        self.heightDark = source.dark?.height
        self.url = source.light.heic
        self.lowResUrl = source.light.heicLowRes
        self.darkUrl = source.dark?.heic
        self.darkLowResUrl = source.dark?.heicLowRes
        self.size = size
        self.shape = maskShape?.shape
        self.colorOverlay = colorOverlay?.asDisplayable(uiConfigProvider: uiConfigProvider)
        self.padding = (padding ?? .zero).edgeInsets
        self.margin = (margin ?? .zero).edgeInsets
        self.border = border?.border(uiConfigProvider: uiConfigProvider)
        self.shadow = shadow?.shadow(uiConfigProvider: uiConfigProvider, colorScheme: colorScheme)
        self.contentMode = fitMode.contentMode
    }

}

#endif
