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

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ImageComponentViewModel {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    private let localizationProvider: LocalizationProvider
    private let component: PaywallComponent.ImageComponent

    private let imageInfo: PaywallComponent.ThemeImageUrls
    private let presentedOverrides: PresentedOverrides<LocalizedImagePartial>?

    init(localizationProvider: LocalizationProvider, component: PaywallComponent.ImageComponent) throws {
        self.localizationProvider = localizationProvider
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
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        apply: @escaping (ImageComponentStyle) -> some View
    ) -> some View {
        let localizedPartial = LocalizedImagePartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: self.presentedOverrides
        )
        let partial = localizedPartial?.partial

        let style = ImageComponentStyle(
            visible: partial?.visible ?? true,
            source: localizedPartial?.imageInfo ?? self.imageInfo,
            size: partial?.size ?? self.component.size,
            fitMode: partial?.fitMode ?? self.component.fitMode,
            maskShape: partial?.maskShape ?? self.component.maskShape,
            gradientColors: partial?.gradientColors ?? self.component.gradientColors
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
                gradientColors: otherPartial?.gradientColors ?? basePartial?.gradientColors
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
    let gradientColors: [Color]
    let contentMode: ContentMode

    init(
        visible: Bool = true,
        source: PaywallComponent.ThemeImageUrls,
        size: PaywallComponent.Size,
        fitMode: PaywallComponent.FitMode,
        maskShape: PaywallComponent.MaskShape? = nil,
        gradientColors: [PaywallComponent.ColorHex]? = nil
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
        self.gradientColors = gradientColors?.compactMap { $0.toColor(fallback: Color.clear) } ?? []
        self.contentMode = fitMode.contentMode
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.MaskShape {

    var shape: ShapeModifier.Shape? {
        switch self {
        case .rectangle(let cornerRadiuses):
            let corners = cornerRadiuses.flatMap { cornerRadiuses in
                ShapeModifier.RadiusInfo(
                    topLeft: cornerRadiuses.topLeading,
                    topRight: cornerRadiuses.topTrailing,
                    bottomLeft: cornerRadiuses.bottomLeading,
                    bottomRight: cornerRadiuses.bottomTrailing
                )
            }
            return .rectangle(corners)
        case .pill:
            return .pill
        case .concave:
            return .concave
        case .convex:
            return .convex
        }
    }

}

#endif
