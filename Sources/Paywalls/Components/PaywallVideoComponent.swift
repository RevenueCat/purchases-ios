//
//  PaywallVideoComponent.swift
//
//
//  Created by Jacob Rakidzich 8/11/25.
//
// swiftlint:disable missing_docs

import Foundation

extension PaywallComponent {

    // Need to add source with the urls

    public final class VideoComponent: PaywallComponentBase {

        let type: ComponentType
        public let source: ThemeVideoUrls
        public let visible: Bool?
        public let videoID: String
        public let showControls: Bool
        public let autoplay: Bool
        public let loop: Bool
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
            videoID: String,
            showControls: Bool = false,
            autoplay: Bool = true,
            loop: Bool = true,
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
            self.visible = visible
            self.videoID = videoID
            self.showControls = showControls
            self.autoplay = autoplay
            self.loop = loop
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
            hasher.combine(videoID)
            hasher.combine(showControls)
            hasher.combine(autoplay)
            hasher.combine(loop)
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
        }

        public static func == (lhs: VideoComponent, rhs: VideoComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.videoID == rhs.videoID &&
                   lhs.showControls == rhs.showControls &&
                   lhs.autoplay == rhs.autoplay &&
                   lhs.loop == rhs.loop &&
                   lhs.size == rhs.size &&
                   lhs.fitMode == rhs.fitMode &&
                   lhs.maskShape == rhs.maskShape &&
                   lhs.colorOverlay == rhs.colorOverlay &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.border == rhs.border &&
                   lhs.shadow == rhs.shadow &&
                   lhs.overrides == rhs.overrides
                   lhs.source == rhs.source
        }
    }

    public final class PartialVideoComponent: PaywallPartialComponent {

        public let source: ThemeVideoUrls?
        public let visible: Bool?
        public let videoID: String?
        public let showControls: Bool?
        public let autoplay: Bool?
        public let loop: Bool?
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
            visible: Bool? = true,
            videoID: String? = nil,
            showControls: Bool? = nil,
            autoplay: Bool? = nil,
            loop: Bool? = nil,
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
            self.visible = visible
            self.videoID = videoID
            self.showControls = showControls
            self.autoplay = autoplay
            self.loop = loop
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
            hasher.combine(visible)
            hasher.combine(videoID)
            hasher.combine(showControls)
            hasher.combine(autoplay)
            hasher.combine(loop)
            hasher.combine(size)
            hasher.combine(fitMode)
            hasher.combine(maskShape)
            hasher.combine(colorOverlay)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(border)
            hasher.combine(shadow)
        }

        public static func == (lhs: PartialVideoComponent, rhs: PartialVideoComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                   lhs.videoID == rhs.videoID &&
                   lhs.showControls == rhs.showControls &&
                   lhs.autoplay == rhs.autoplay &&
                   lhs.loop == rhs.loop &&
                   lhs.size == rhs.size &&
                   lhs.fitMode == rhs.fitMode &&
                   lhs.maskShape == rhs.maskShape &&
                   lhs.colorOverlay == rhs.colorOverlay &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.border == rhs.border &&
                   lhs.shadow == rhs.shadow
                   lhs.source == rhs.source
        }
    }
}
