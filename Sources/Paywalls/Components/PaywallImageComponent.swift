//
//  PaywallImageComponent.swift
//
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct ImageComponent: PaywallComponentBase {

        let type: ComponentType
        public let source: ThemeImageUrls
        public let size: Size
        public let overrideSourceLid: LocalizationKey?
        public let maskShape: MaskShape?
        public let gradientColors: [ColorHex]?
        public let fitMode: FitMode

        public let overrides: ComponentOverrides<PartialImageComponent>?

        public init(
            source: ThemeImageUrls,
            size: Size = .init(width: .fill, height: .fit),
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode = .fit,
            maxHeight: CGFloat? = nil,
            maskShape: MaskShape? = nil,
            gradientColors: [ColorHex]? = [],
            overrides: ComponentOverrides<PartialImageComponent>? = nil
        ) {
            self.type = .image
            self.source = source
            self.size = size
            self.overrideSourceLid = overrideSourceLid
            self.fitMode = fitMode
            self.maskShape = maskShape
            self.gradientColors = gradientColors
            self.overrides = overrides
        }

    }

    struct PartialImageComponent: PartialComponent {

        public let visible: Bool?
        public let source: ThemeImageUrls?
        public let size: Size?
        public let overrideSourceLid: LocalizationKey?
        public let maskShape: MaskShape?
        public let gradientColors: [ColorHex]?
        public let fitMode: FitMode?

        public init(
            visible: Bool? = true,
            source: ThemeImageUrls? = nil,
            size: Size? = nil,
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode? = nil,
            maskShape: MaskShape? = nil,
            gradientColors: [ColorHex]? = nil
        ) {
            self.visible = visible
            self.source = source
            self.size = size
            self.overrideSourceLid = overrideSourceLid
            self.fitMode = fitMode
            self.maskShape = maskShape
            self.gradientColors = gradientColors
        }

    }

}

#endif
