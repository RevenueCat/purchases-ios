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
        public let overrideSourceLid: LocalizationKey?
        public let cornerRadiuses: CornerRadiuses
        public let gradientColors: [ColorHex]?
        public let maxHeight: CGFloat?
        public let fitMode: FitMode

        public init(
            source: ThemeImageUrls,
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode = .fit,
            maxHeight: CGFloat? = nil,
            cornerRadiuses: CornerRadiuses = .zero,
            gradientColors: [ColorHex]? = []
        ) {
            self.type = .image
            self.source = source
            self.overrideSourceLid = overrideSourceLid
            self.fitMode = fitMode
            self.maxHeight = maxHeight
            self.cornerRadiuses = cornerRadiuses
            self.gradientColors = gradientColors
        }

    }

}

#endif
