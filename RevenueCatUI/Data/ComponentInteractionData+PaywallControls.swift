//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentInteractionData+PaywallControls.swift
//
//  Created by Monika Mateska on 08/04/2026.

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEvent.ComponentInteractionData {

    // MARK: - Tabs

    static func paywallTabControlButtonSelection(
        componentName: String?,
        destinationTabId: String,
        originIndex: Int?,
        destinationIndex: Int?,
        originContextName: String?,
        destinationContextName: String?,
        defaultIndex: Int?
    ) -> Self {
        return .init(
            componentType: .tab,
            componentName: componentName,
            componentValue: destinationTabId,
            originIndex: originIndex,
            destinationIndex: destinationIndex,
            originContextName: originContextName,
            destinationContextName: destinationContextName,
            defaultIndex: defaultIndex
        )
    }

    static func paywallTabControlToggle(
        componentName: String?,
        isOn: Bool
    ) -> Self {
        return .init(
            componentType: .toggleSwitch,
            componentName: componentName,
            componentValue: isOn ? "on" : "off"
        )
    }

    // MARK: - Carousel

    static func paywallCarouselPageChange(
        componentName: String?,
        destinationPageIndex: Int,
        originPageIndex: Int,
        defaultPageIndex: Int,
        originContextName: String?,
        destinationContextName: String?
    ) -> Self {
        return .init(
            componentType: .carousel,
            componentName: componentName,
            componentValue: String(destinationPageIndex),
            originIndex: originPageIndex,
            destinationIndex: destinationPageIndex,
            originContextName: originContextName,
            destinationContextName: destinationContextName,
            defaultIndex: defaultPageIndex
        )
    }

    // MARK: - Button (non-purchase)

    static func paywallNonPurchaseButtonAction(
        componentName: String?,
        componentValue: String,
        componentURL: URL? = nil
    ) -> Self {
        return .init(
            componentType: .button,
            componentName: componentName,
            componentValue: componentValue,
            componentURL: componentURL
        )
    }

    static func paywallFooterTermsLink(url: URL) -> Self {
        return .init(
            componentType: .button,
            componentName: PaywallComponentInteraction.termsLinkName,
            componentValue: PaywallComponentInteraction.ComponentValue.navigateToTerms.rawValue,
            componentURL: url
        )
    }

    static func paywallFooterPrivacyLink(url: URL) -> Self {
        return .init(
            componentType: .button,
            componentName: PaywallComponentInteraction.privacyLinkName,
            componentValue: PaywallComponentInteraction.ComponentValue.navigateToPrivacyPolicy.rawValue,
            componentURL: url
        )
    }

    static func paywallFooterToggleAllPlans() -> Self {
        return .init(
            componentType: .button,
            componentName: PaywallComponentInteraction.allPlansButtonName,
            componentValue: PaywallComponentInteraction.ComponentValue.toggleAllPlans.rawValue
        )
    }

    static func paywallFooterRestorePurchases() -> Self {
        return .init(
            componentType: .button,
            componentName: PaywallComponentInteraction.restoreButtonName,
            componentValue: PaywallComponentInteraction.ComponentValue.restorePurchases.rawValue
        )
    }

    // MARK: - Text

    static func paywallTextMarkdownLinkTap(
        componentName: String?,
        url: URL
    ) -> Self {
        return .init(
            componentType: .text,
            componentName: componentName,
            componentValue: "navigate_to_url",
            componentURL: url
        )
    }

}
