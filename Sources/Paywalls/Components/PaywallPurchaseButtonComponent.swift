//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct PurchaseButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let cta: LocalizationKey
        public let ctaIntroOffer: LocalizationKey?
        public let fontFamily: String?
        public let fontWeight: FontWeight
        public let color: ColorInfo
        public let textStyle: TextStyle
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorInfo?
        public let padding: Padding
        public let margin: Padding
        public let shape: Shape
        public let cornerRadiuses: CornerRadiuses?

        public init(
            cta: LocalizationKey,
            ctaIntroOffer: LocalizationKey? = nil,
            fontFamily: String? = nil,
            fontWeight: FontWeight = .regular,
            color: ColorInfo,
            backgroundColor: ColorInfo? = nil,
            padding: Padding = .default,
            margin: Padding = .default,
            textStyle: TextStyle = .body,
            horizontalAlignment: HorizontalAlignment = .center,
            shape: Shape = .pill,
            cornerRadiuses: CornerRadiuses? = nil
        ) {
            self.type = .purchaseButton
            self.cta = cta
            self.ctaIntroOffer = ctaIntroOffer
            self.fontFamily = fontFamily
            self.fontWeight = fontWeight
            self.color = color
            self.backgroundColor = backgroundColor
            self.padding = padding
            self.margin = margin
            self.textStyle = textStyle
            self.horizontalAlignment = horizontalAlignment
            self.shape = shape
            self.cornerRadiuses = cornerRadiuses
        }

    }

}

extension PaywallComponent.PurchaseButtonComponent {

    enum CodingKeys: String, CodingKey {
        case type
        case cta = "cta_lid"
        case ctaIntroOffer = "cta_intro_offer_lid"
        case fontFamily
        case fontWeight
        case color
        case textStyle
        case horizontalAlignment
        case backgroundColor
        case padding
        case margin
        case shape
        case cornerRadiuses
    }

}

#endif
