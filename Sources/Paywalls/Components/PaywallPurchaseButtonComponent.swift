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
        public let ctaLid: LocalizationKey
        public let ctaIntroOfferLid: LocalizationKey
        public let fontFamily: String?
        public let fontWeight: FontWeight
        public let color: ColorInfo
        public let textStyle: TextStyle
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorInfo?
        public let padding: Padding
        public let margin: Padding

        public init(
            ctaLid: LocalizationKey,
            ctaIntroOfferLid: LocalizationKey,
            fontFamily: String? = nil,
            fontWeight: FontWeight = .regular,
            color: ColorInfo,
            backgroundColor: ColorInfo? = nil,
            padding: Padding = .default,
            margin: Padding = .default,
            textStyle: TextStyle = .body,
            horizontalAlignment: HorizontalAlignment = .center
        ) {
            self.type = .purchaseButton
            self.ctaLid = ctaLid
            self.ctaIntroOfferLid = ctaIntroOfferLid
            self.fontFamily = fontFamily
            self.fontWeight = fontWeight
            self.color = color
            self.backgroundColor = backgroundColor
            self.padding = padding
            self.margin = margin
            self.textStyle = textStyle
            self.horizontalAlignment = horizontalAlignment
        }

    }

}

#endif
