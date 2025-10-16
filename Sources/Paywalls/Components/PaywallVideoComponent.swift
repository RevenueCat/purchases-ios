//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallVideoComponent.swift
//
//  Created by Jacob Zivan Rakidzich on 8/11/25.
//
// swiftlint:disable missing_docs

import Foundation

extension PaywallComponent {

    public final class VideoComponent: PaywallComponentBase {

        let type: ComponentType
        public let source: ThemeVideoUrls
        public let fallbackSource: ThemeImageUrls?
        public let visible: Bool?
        public let showControls: Bool
        public let autoPlay: Bool
        public let loop: Bool
        public let muteAudio: Bool
        public let size: Size
        public let fitMode: FitMode
        public let maskShape: MaskShape?
        public let colorOverlay: ColorScheme?
        public let padding: Padding?
        public let margin: Padding?
        public let border: Border?
        public let shadow: Shadow?

        public let overrides: ComponentOverrides<PartialVideoComponent>?

        public init(
            visible: Bool? = nil,
            source: ThemeVideoUrls,
            fallbackSource: ThemeImageUrls? = nil,
            showControls: Bool = false,
            autoPlay: Bool = true,
            loop: Bool = true,
            muteAudio: Bool = true,
            size: Size = .init(width: .fill, height: .fit),
            fitMode: FitMode = .fit,
            maskShape: MaskShape? = nil,
            colorOverlay: ColorScheme? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil,
            overrides: ComponentOverrides<PartialVideoComponent>? = nil
        ) {
            self.type = .video
            self.source = source
            self.fallbackSource = fallbackSource
            self.visible = visible
            self.showControls = showControls
            self.autoPlay = autoPlay
            self.loop = loop
            self.muteAudio = muteAudio
            self.size = size
            self.fitMode = fitMode
            self.maskShape = maskShape
            self.colorOverlay = colorOverlay
            self.padding = padding
            self.margin = margin
            self.border = border
            self.shadow = shadow
            self.overrides = overrides
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(showControls)
            hasher.combine(autoPlay)
            hasher.combine(loop)
            hasher.combine(muteAudio)
            hasher.combine(size)
            hasher.combine(fitMode)
            hasher.combine(maskShape)
            hasher.combine(colorOverlay)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(overrides)
            hasher.combine(source)
            hasher.combine(fallbackSource)
        }

        public static func == (lhs: VideoComponent, rhs: VideoComponent) -> Bool {
            return lhs.type == rhs.type &&
            lhs.visible == rhs.visible &&
            lhs.showControls == rhs.showControls &&
            lhs.autoPlay == rhs.autoPlay &&
            lhs.loop == rhs.loop &&
            lhs.muteAudio == rhs.muteAudio &&
            lhs.size == rhs.size &&
            lhs.fitMode == rhs.fitMode &&
            lhs.maskShape == rhs.maskShape &&
            lhs.colorOverlay == rhs.colorOverlay &&
            lhs.padding == rhs.padding &&
            lhs.margin == rhs.margin &&
            lhs.border == rhs.border &&
            lhs.shadow == rhs.shadow &&
            lhs.overrides == rhs.overrides &&
            lhs.fallbackSource == rhs.fallbackSource &&
            lhs.source == rhs.source
        }
    }

    public final class PartialVideoComponent: PaywallPartialComponent {

        public let source: ThemeVideoUrls?
        public let fallbackSource: ThemeImageUrls?
        public let visible: Bool?
        public let showControls: Bool?
        public let autoPlay: Bool?
        public let loop: Bool?
        public let muteAudio: Bool?
        public let size: Size?
        public let fitMode: FitMode?
        public let maskShape: MaskShape?
        public let colorOverlay: ColorScheme?
        public let padding: Padding?
        public let margin: Padding?
        public let border: Border?
        public let shadow: Shadow?

        public init(
            source: ThemeVideoUrls? = nil,
            fallbackSource: ThemeImageUrls? = nil,
            visible: Bool? = true,
            showControls: Bool? = nil,
            autoPlay: Bool? = nil,
            loop: Bool? = nil,
            muteAudio: Bool? = nil,
            size: Size? = nil,
            fitMode: FitMode? = nil,
            maskShape: MaskShape? = nil,
            colorOverlay: ColorScheme? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil
        ) {
            self.source = source
            self.fallbackSource = fallbackSource
            self.visible = visible
            self.showControls = showControls
            self.autoPlay = autoPlay
            self.loop = loop
            self.muteAudio = muteAudio
            self.size = size
            self.fitMode = fitMode
            self.maskShape = maskShape
            self.colorOverlay = colorOverlay
            self.padding = padding
            self.margin = margin
            self.border = border
            self.shadow = shadow
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(source)
            hasher.combine(fallbackSource)
            hasher.combine(visible)
            hasher.combine(showControls)
            hasher.combine(autoPlay)
            hasher.combine(loop)
            hasher.combine(muteAudio)
            hasher.combine(size)
            hasher.combine(fitMode)
            hasher.combine(maskShape)
            hasher.combine(colorOverlay)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(fallbackSource)
        }

        public static func == (lhs: PartialVideoComponent, rhs: PartialVideoComponent) -> Bool {
            return lhs.visible == rhs.visible &&
            lhs.showControls == rhs.showControls &&
            lhs.autoPlay == rhs.autoPlay &&
            lhs.loop == rhs.loop &&
            lhs.muteAudio == rhs.muteAudio &&
            lhs.size == rhs.size &&
            lhs.fitMode == rhs.fitMode &&
            lhs.maskShape == rhs.maskShape &&
            lhs.colorOverlay == rhs.colorOverlay &&
            lhs.padding == rhs.padding &&
            lhs.margin == rhs.margin &&
            lhs.border == rhs.border &&
            lhs.shadow == rhs.shadow &&
            lhs.fallbackSource == rhs.fallbackSource &&
            lhs.source == rhs.source
        }
    }
}
