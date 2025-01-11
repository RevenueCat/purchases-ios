//
//  PaywallImageComponent.swift
//
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

//source: ImageScheme | None = None
//override_source_lid: LocalizationId | None = None
//color_overlay: ColorSchemes | None = None
//fit_mode: FitMode | None = None
//mask_shape: MaskShape | None = None
//size: Size | None = None
//padding: Spacing | None = None
//margin: Spacing | None = None
//border: Border | None = None
//shadow: Shadow | None = None

public extension PaywallComponent {

    struct ImageComponent: PaywallComponentBase {

        let type: ComponentType
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

    }

    struct PartialImageComponent: PartialComponent {

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

    }

}

#endif
