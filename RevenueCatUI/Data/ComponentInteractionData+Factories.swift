//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentInteractionData+Factories.swift
//
//  Created by Monika Mateska on 08/04/2026.

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEvent.ComponentInteractionData {

    // MARK: - Tabs

    struct TabControlButtonSelectionMetadata: Sendable {
        let originIndex: Int?
        let destinationIndex: Int?
        let originContextName: String?
        let destinationContextName: String?
        let defaultIndex: Int?
    }

    static func paywallTabControlButtonSelection(
        componentName: String?,
        destinationTabId: String,
        metadata: TabControlButtonSelectionMetadata
    ) -> Self {
        return .init(
            componentType: .tab,
            componentName: componentName,
            componentValue: destinationTabId,
            originIndex: metadata.originIndex,
            destinationIndex: metadata.destinationIndex,
            originContextName: metadata.originContextName,
            destinationContextName: metadata.destinationContextName,
            defaultIndex: metadata.defaultIndex
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

    struct CarouselPageChangeContext: Sendable {
        let originPageIndex: Int
        let defaultPageIndex: Int
        let originContextName: String?
        let destinationContextName: String?
    }

    static func paywallCarouselPageChange(
        componentName: String?,
        destinationPageIndex: Int,
        context: CarouselPageChangeContext
    ) -> Self {
        return .init(
            componentType: .carousel,
            componentName: componentName,
            componentValue: String(destinationPageIndex),
            originIndex: context.originPageIndex,
            destinationIndex: destinationPageIndex,
            originContextName: context.originContextName,
            destinationContextName: context.destinationContextName,
            defaultIndex: context.defaultPageIndex
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

    // MARK: - Button (purchase)

    static func paywallPurchaseButtonAction(
        componentName: String? = nil,
        componentValue: String,
        componentURL: URL? = nil,
        currentPackageIdentifier: String? = nil,
        currentProductIdentifier: String? = nil
    ) -> Self {
        return .init(
            componentType: .purchaseButton,
            componentName: componentName,
            componentValue: componentValue,
            componentURL: componentURL,
            currentPackageIdentifier: currentPackageIdentifier,
            currentProductIdentifier: currentProductIdentifier
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

    // MARK: - Package selection

    /// Package-selection sheet became visible: `component_value` is `open`.
    /// `current*` reflects the root paywall selection.
    static func paywallPackageSelectionSheetOpen(
        sheetComponentName: String?,
        rootSelectedPackage: Package?
    ) -> Self {
        return .init(
            componentType: .packageSelectionSheet,
            componentName: sheetComponentName,
            componentValue: "open",
            currentPackageIdentifier: rootSelectedPackage?.identifier,
            currentProductIdentifier: rootSelectedPackage?.storeProduct.productIdentifier
        )
    }

    /// Package-selection sheet dismissed: `component_value` is `close`.
    /// `current*` reflects the sheet selection before dismiss; `resulting*` reflects the root paywall after dismiss
    /// (e.g. revert to default).
    static func paywallPackageSelectionSheetClose(
        sheetComponentName: String?,
        sheetSelectedPackage: Package?,
        resultingRootPackage: Package?
    ) -> Self {
        return .init(
            componentType: .packageSelectionSheet,
            componentName: sheetComponentName,
            componentValue: "close",
            currentPackageIdentifier: sheetSelectedPackage?.identifier,
            resultingPackageIdentifier: resultingRootPackage?.identifier,
            currentProductIdentifier: sheetSelectedPackage?.storeProduct.productIdentifier,
            resultingProductIdentifier: resultingRootPackage?.storeProduct.productIdentifier
        )
    }

    static func paywallPackageRowSelection(
        componentName: String? = nil,
        destination: Package,
        origin: Package?,
        defaultPackage: Package? = nil
    ) -> Self {
        return .init(
            componentType: .package,
            componentName: componentName,
            componentValue: destination.identifier,
            originPackageIdentifier: origin?.identifier,
            destinationPackageIdentifier: destination.identifier,
            defaultPackageIdentifier: defaultPackage?.identifier,
            originProductIdentifier: origin?.storeProduct.productIdentifier,
            destinationProductIdentifier: destination.storeProduct.productIdentifier,
            defaultProductIdentifier: defaultPackage?.storeProduct.productIdentifier
        )
    }

    static func paywallTierSelection(
        tierDisplayName: String,
        componentName: String? = nil,
        originPackage: Package?,
        destinationPackage: Package?
    ) -> Self {
        return .init(
            componentType: .tab,
            componentName: componentName,
            componentValue: tierDisplayName,
            originPackageIdentifier: originPackage?.identifier,
            destinationPackageIdentifier: destinationPackage?.identifier,
            originProductIdentifier: originPackage?.storeProduct.productIdentifier,
            destinationProductIdentifier: destinationPackage?.storeProduct.productIdentifier
        )
    }

}
