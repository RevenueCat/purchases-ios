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

    final class ImageComponent: PaywallComponentBase {

        let type: ComponentType
        public let source: ThemeImageUrls
        public let overrideSourceLid: LocalizationKey?
        public let cornerRadiuses: CornerRadiuses
        public let gradientColors: [ColorHex]?
        public let maxHeight: CGFloat?
        public let fitMode: FitMode
        public let selectedComponent: ImageComponent?

        public init(
            source: ThemeImageUrls,
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode = .fit,
            maxHeight: CGFloat? = nil,
            cornerRadiuses: CornerRadiuses = .zero,
            gradientColors: [ColorHex]? = [],
            selectedComponent: ImageComponent? = nil
        ) {
            self.type = .image
            self.source = source
            self.overrideSourceLid = overrideSourceLid
            self.fitMode = fitMode
            self.maxHeight = maxHeight
            self.cornerRadiuses = cornerRadiuses
            self.gradientColors = gradientColors
            self.selectedComponent = selectedComponent
        }
    }

}

extension PaywallComponent.ImageComponent {

    public static func == (lhs: PaywallComponent.ImageComponent, rhs: PaywallComponent.ImageComponent) -> Bool {
        return lhs.type == rhs.type &&
               lhs.url == rhs.url &&
               lhs.fitMode == rhs.fitMode &&
               lhs.maxHeight == rhs.maxHeight &&
               lhs.cornerRadius == rhs.cornerRadius &&
               lhs.gradientColors == rhs.gradientColors &&
               lhs.selectedComponent == rhs.selectedComponent
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(url)
        hasher.combine(fitMode)
        hasher.combine(maxHeight)
        hasher.combine(cornerRadius)
        hasher.combine(gradientColors)
        hasher.combine(selectedComponent)
    }

}

#endif
