//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoComponentViewModel.swift
//
//  Created by Jacob Zivan Rakidzich on 8/11/25.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class VideoComponentViewModel {

    let localizationProvider: LocalizationProvider
    let uiConfigProvider: UIConfigProvider
    private let component: PaywallComponent.VideoComponent

    var imageSource: PaywallComponent.ThemeImageUrls? { component.fallbackSource }

    private let presentedOverrides: PresentedOverrides<LocalizedVideoPartial>?

    init(
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        component: PaywallComponent.VideoComponent
    ) {
        self.localizationProvider = localizationProvider
        self.uiConfigProvider = uiConfigProvider
        self.component = component

        self.presentedOverrides = self.component.overrides?.toPresentedOverrides {
            LocalizedVideoPartial.create(from: $0, using: localizationProvider.localizedStrings)
        } ?? []
    }

    @ViewBuilder
    // swiftlint:disable:next function_parameter_count
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        colorScheme: ColorScheme,
        @ViewBuilder apply: @escaping (VideoComponentStyle) -> some View
    ) -> some View {
        let localizedPartial = LocalizedVideoPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )
        let partial = localizedPartial?.partial

        let style = VideoComponentStyle(
            visible: partial?.visible ?? self.component.visible ?? true,
            showControls: partial?.showControls ?? self.component.showControls,
            autoPlay: partial?.autoPlay ?? self.component.autoPlay,
            loop: partial?.loop ?? self.component.loop,
            url: partial?.source?.light.url ?? self.component.source.light.url,
            lowResUrl: partial?.source?.light.urlLowRes ?? self.component.source.light.urlLowRes,
            darkUrl: partial?.source?.dark?.url ?? self.component.source.dark?.url,
            darkLowResUrl: partial?.source?.dark?.urlLowRes ?? self.component.source.dark?.urlLowRes,
            size: partial?.size ?? self.component.size,
            widthLight: partial?.source?.light.width ?? self.component.source.light.width,
            heightLight: partial?.source?.light.height ?? self.component.source.light.height,
            widthDark: partial?.source?.dark?.width ?? self.component.source.dark?.width,
            heightDark: partial?.source?.dark?.height ?? self.component.source.dark?.height,
            muteAudio: partial?.muteAudio ?? self.component.muteAudio,
            fitMode: partial?.fitMode ?? self.component.fitMode,
            maskShape: partial?.maskShape ?? self.component.maskShape,
            colorOverlay: partial?.colorOverlay ?? self.component.colorOverlay,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            border: partial?.border ?? self.component.border,
            shadow: partial?.shadow ?? self.component.shadow,
            checksum: partial?.source?.light.checksum ?? self.component.source.light.checksum,
            checksumLowRes: partial?.source?.light.checksumLowRes ?? self.component.source.light.checksumLowRes,
            darkChecksum: partial?.source?.dark?.checksum ?? self.component.source.dark?.checksum,
            darkChecksumLowRes: partial?.source?.dark?.checksumLowRes ?? self.component.source.dark?.checksumLowRes,
            uiConfigProvider: self.uiConfigProvider,
            colorScheme: colorScheme
        )

        apply(style)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VideoComponentViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(component)
    }

    static func == (lhs: VideoComponentViewModel, rhs: VideoComponentViewModel) -> Bool {
        lhs.component == rhs.component
    }
}

struct LocalizedVideoPartial: PresentedPartial {

    let partial: PaywallComponent.PartialVideoComponent

    static func combine(_ base: Self?, with other: Self?) -> Self {
        let otherPartial = other?.partial
        let basePartial = base?.partial

        return LocalizedVideoPartial(
            partial: PaywallComponent.PartialVideoComponent(
                source: otherPartial?.source ?? basePartial?.source,
                visible: otherPartial?.visible ?? basePartial?.visible,
                showControls: otherPartial?.showControls ?? basePartial?.showControls,
                autoPlay: otherPartial?.autoPlay ?? basePartial?.autoPlay,
                loop: otherPartial?.loop ?? basePartial?.loop,
                size: otherPartial?.size ?? basePartial?.size,
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

extension LocalizedVideoPartial {

    static func create(
        from partial: PaywallComponent.PartialVideoComponent,
        using localizedStrings: PaywallComponent.LocalizationDictionary
    ) -> LocalizedVideoPartial {
        return LocalizedVideoPartial(
            partial: partial
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct VideoComponentStyle {

    let visible: Bool
    let showControls: Bool
    let autoPlay: Bool
    let loop: Bool
    let url: URL
    let lowResUrl: URL?
    let darkUrl: URL?
    let darkLowResUrl: URL?
    let size: PaywallComponent.Size
    let widthLight: Int
    let heightLight: Int
    let widthDark: Int?
    let heightDark: Int?
    let muteAudio: Bool
    let shape: ShapeModifier.Shape?
    let colorOverlay: DisplayableColorScheme?
    let padding: EdgeInsets
    let margin: EdgeInsets
    let border: ShapeModifier.BorderInfo?
    let shadow: ShadowModifier.ShadowInfo?
    let checksum: Checksum?
    let checksumLowRes: Checksum?
    let darkChecksum: Checksum?
    let darkChecksumLowRes: Checksum?
    let contentMode: ContentMode

    init(
        visible: Bool = true,
        showControls: Bool,
        autoPlay: Bool,
        loop: Bool,
        url: URL,
        lowResUrl: URL?,
        darkUrl: URL? = nil,
        darkLowResUrl: URL? = nil,
        size: PaywallComponent.Size,
        widthLight: Int,
        heightLight: Int,
        widthDark: Int?,
        heightDark: Int?,
        muteAudio: Bool,
        fitMode: PaywallComponent.FitMode,
        maskShape: PaywallComponent.MaskShape? = nil,
        colorOverlay: PaywallComponent.ColorScheme? = nil,
        padding: PaywallComponent.Padding? = nil,
        margin: PaywallComponent.Padding? = nil,
        border: PaywallComponent.Border? = nil,
        shadow: PaywallComponent.Shadow? = nil,
        checksum: Checksum? = nil,
        checksumLowRes: Checksum? = nil,
        darkChecksum: Checksum? = nil,
        darkChecksumLowRes: Checksum? = nil,
        uiConfigProvider: UIConfigProvider,
        colorScheme: ColorScheme
    ) {
        self.visible = visible
        self.showControls = showControls
        self.autoPlay = autoPlay
        self.loop = loop
        self.url = url
        self.lowResUrl = lowResUrl
        self.darkLowResUrl = darkLowResUrl
        self.darkUrl = darkUrl
        self.size = size
        self.widthLight = widthLight
        self.heightLight = heightLight
        self.widthDark = widthDark
        self.heightDark = heightDark
        self.muteAudio = muteAudio
        self.shape = maskShape?.shape
        self.colorOverlay = colorOverlay?.asDisplayable(uiConfigProvider: uiConfigProvider)
        self.padding = (padding ?? .zero).edgeInsets
        self.margin = (margin ?? .zero).edgeInsets
        self.border = border?.border(uiConfigProvider: uiConfigProvider)
        self.shadow = shadow?.shadow(uiConfigProvider: uiConfigProvider, colorScheme: colorScheme)
        self.checksum = checksum
        self.checksumLowRes = checksumLowRes
        self.darkChecksum = darkChecksum
        self.darkChecksumLowRes = darkChecksumLowRes
        self.contentMode = fitMode.contentMode
    }

    func viewData(forDarkMode: Bool) -> ViewData {
        if forDarkMode {
            let (resolvedUrl, resolvedChecksum): (URL, Checksum?) = {
                if let darkUrl {
                    return (darkUrl, darkChecksum)
                } else {
                    return (url, self.checksum)
                }
            }()

            return .init(
                url: resolvedUrl,
                checksum: resolvedChecksum,
                lowResUrl: darkLowResUrl,
                lowResChecksum: darkChecksumLowRes
            )
        } else {
            return .init(
                url: url,
                checksum: checksum,
                lowResUrl: lowResUrl,
                lowResChecksum: checksumLowRes
            )
        }
    }

    struct ViewData {
        let url: URL
        let checksum: Checksum?
        let lowResUrl: URL?
        let lowResChecksum: Checksum?
    }
}

#endif
