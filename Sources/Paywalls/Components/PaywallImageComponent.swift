//
//  PaywallImageComponent.swift
//
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

public extension PaywallComponent {

    final class ImageComponent: PaywallComponentBase {

        let type: ComponentType
        public let visible: Bool?
        public let source: ThemeImageUrls
        public let size: Size
        public let overrideSourceLid: LocalizationKey?
        public let fitMode: FitMode
        public let maskShape: MaskShape?
        public let colorOverlay: ColorScheme?
        public let padding: Padding?
        public let margin: Padding?
        public let border: Border?
        public let shadow: Shadow?

        public let overrides: ComponentOverrides<PartialImageComponent>?

        public init(
            visible: Bool? = nil,
            source: ThemeImageUrls,
            size: Size = .init(width: .fill, height: .fit),
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode = .fit,
            maskShape: MaskShape? = nil,
            colorOverlay: ColorScheme? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil,
            overrides: ComponentOverrides<PartialImageComponent>? = nil
        ) {
            self.type = .image
            self.visible = visible
            self.source = source
            self.size = size
            self.overrideSourceLid = overrideSourceLid
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
            hasher.combine(source)
            hasher.combine(size)
            hasher.combine(overrideSourceLid)
            hasher.combine(fitMode)
            hasher.combine(maskShape)
            hasher.combine(colorOverlay)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(overrides)
        }

        public static func == (lhs: ImageComponent, rhs: ImageComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.source == rhs.source &&
                   lhs.size == rhs.size &&
                   lhs.overrideSourceLid == rhs.overrideSourceLid &&
                   lhs.fitMode == rhs.fitMode &&
                   lhs.maskShape == rhs.maskShape &&
                   lhs.colorOverlay == rhs.colorOverlay &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.border == rhs.border &&
                   lhs.shadow == rhs.shadow &&
                   lhs.overrides == rhs.overrides
        }
    }

    final class PartialImageComponent: PaywallPartialComponent {

        public let visible: Bool?
        public let source: ThemeImageUrls?
        public let size: Size?
        public let overrideSourceLid: LocalizationKey?
        public let maskShape: MaskShape?
        public let fitMode: FitMode?
        public let colorOverlay: ColorScheme?
        public let padding: Padding?
        public let margin: Padding?
        public let border: Border?
        public let shadow: Shadow?

        public init(
            visible: Bool? = true,
            source: ThemeImageUrls? = nil,
            size: Size? = nil,
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode? = nil,
            maskShape: MaskShape? = nil,
            colorOverlay: ColorScheme? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil
        ) {
            self.visible = visible
            self.source = source
            self.size = size
            self.overrideSourceLid = overrideSourceLid
            self.fitMode = fitMode
            self.maskShape = maskShape
            self.colorOverlay = colorOverlay
            self.padding = padding
            self.margin = margin
            self.border = border
            self.shadow = shadow
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(source)
            hasher.combine(size)
            hasher.combine(overrideSourceLid)
            hasher.combine(fitMode)
            hasher.combine(maskShape)
            hasher.combine(colorOverlay)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(border)
            hasher.combine(shadow)
        }

        public static func == (lhs: PartialImageComponent, rhs: PartialImageComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                   lhs.source == rhs.source &&
                   lhs.size == rhs.size &&
                   lhs.overrideSourceLid == rhs.overrideSourceLid &&
                   lhs.fitMode == rhs.fitMode &&
                   lhs.maskShape == rhs.maskShape &&
                   lhs.colorOverlay == rhs.colorOverlay &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.border == rhs.border &&
                   lhs.shadow == rhs.shadow
        }
    }

}
