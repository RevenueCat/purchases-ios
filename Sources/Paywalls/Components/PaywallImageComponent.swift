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
        public let cornerRadiuses: CornerRadiuses?
        public let gradientColors: [ColorHex]?
        public let maxHeight: CGFloat?
        public let fitMode: FitMode

        public let state: ComponentState<PartialImageComponent>?
        public let conditions: ComponentConditions<PartialImageComponent>?

        public init(
            source: ThemeImageUrls,
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode = .fit,
            maxHeight: CGFloat? = nil,
            cornerRadiuses: CornerRadiuses? = nil,
            gradientColors: [ColorHex]? = [],
            state: ComponentState<PartialImageComponent>? = nil,
            conditions: ComponentConditions<PartialImageComponent>? = nil
        ) {
            self.type = .image
            self.source = source
            self.overrideSourceLid = overrideSourceLid
            self.fitMode = fitMode
            self.maxHeight = maxHeight
            self.cornerRadiuses = cornerRadiuses
            self.gradientColors = gradientColors
            self.state = state
            self.conditions = conditions
        }

    }

    struct PartialImageComponent: PartialComponent {

        public let visible: Bool?
        public let source: ThemeImageUrls?
        public let overrideSourceLid: LocalizationKey?
        public let cornerRadiuses: CornerRadiuses?
        public let gradientColors: [ColorHex]?
        public let maxHeight: CGFloat?
        public let fitMode: FitMode?

        public init(
            visible: Bool? = true,
            source: ThemeImageUrls? = nil,
            overrideSourceLid: LocalizationKey? = nil,
            fitMode: FitMode? = nil,
            maxHeight: CGFloat? = nil,
            cornerRadiuses: CornerRadiuses? = nil,
            gradientColors: [ColorHex]? = nil
        ) {
            self.visible = visible
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
