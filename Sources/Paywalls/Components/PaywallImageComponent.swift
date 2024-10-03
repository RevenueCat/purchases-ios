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
        public let cornerRadiuses: CornerRadiuses?
        public let gradientColors: [ColorHex]?
        public let maxHeight: CGFloat?
        public let fitMode: FitMode
        
        public let selectedState: ImageComponent?

        public init(
            source: ThemeImageUrls,
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode = .fit,
            maxHeight: CGFloat? = nil,
            cornerRadiuses: CornerRadiuses? = nil,
            gradientColors: [ColorHex]? = [],
            selectedState: ImageComponent? = nil
        ) {
            self.type = .image
            self.source = source
            self.overrideSourceLid = overrideSourceLid
            self.fitMode = fitMode
            self.maxHeight = maxHeight
            self.cornerRadiuses = cornerRadiuses
            self.gradientColors = gradientColors
            self.selectedState = selectedState
        }

        public static func == (lhs: ImageComponent, rhs: ImageComponent) -> Bool {
            lhs.type == rhs.type &&
            lhs.source == rhs.source &&
            lhs.overrideSourceLid == rhs.overrideSourceLid &&
            lhs.cornerRadiuses == rhs.cornerRadiuses &&
            lhs.gradientColors == rhs.gradientColors &&
            lhs.maxHeight == rhs.maxHeight &&
            lhs.fitMode == rhs.fitMode &&
            lhs.selectedState == rhs.selectedState
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(source)
            hasher.combine(overrideSourceLid)
            hasher.combine(cornerRadiuses)
            hasher.combine(gradientColors)
            hasher.combine(maxHeight)
            hasher.combine(fitMode)
            hasher.combine(selectedState)
        }
    }

}

#endif
