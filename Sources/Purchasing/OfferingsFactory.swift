//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsFactory.swift
//
//  Created by César de la Vega on 7/13/21.
//

import Foundation
import StoreKit

class OfferingsFactory {

    private let systemInfo: SystemInfo

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    func createOfferings(
        from storeProductsByID: [String: StoreProduct],
        contents: Offerings.Contents,
        loadedFromDiskCache: Bool,
        shouldCreatePaywallComponents: Bool = true
    ) -> Offerings? {
        let data = contents.response
        let offerings: [String: Offering] = data
            .offerings
            .compactMap { offeringData in
                createOffering(from: storeProductsByID,
                               offering: offeringData,
                               uiConfig: data.uiConfig,
                               shouldCreatePaywallComponents: shouldCreatePaywallComponents)
            }
            .dictionaryAllowingDuplicateKeys { $0.identifier }

        guard !offerings.isEmpty else {
            return nil
        }

        let storedContents = shouldCreatePaywallComponents
            ? contents
            : contents.removingPaywallComponents()

        return Offerings(offerings: offerings,
                         currentOfferingID: data.currentOfferingId,
                         placements: createPlacement(with: data.placements),
                         targeting: data.targeting.flatMap { .init(revision: $0.revision, ruleId: $0.ruleId) },
                         contents: storedContents,
                         loadedFromDiskCache: loadedFromDiskCache)
    }

    func createOffering(
        from storeProductsByID: [String: StoreProduct],
        offering: OfferingsResponse.Offering,
        uiConfig: UIConfig?,
        shouldCreatePaywallComponents: Bool = true
    ) -> Offering? {
        let availablePackages: [Package] = offering.packages.compactMap { package in
            createPackage(with: package, productsByID: storeProductsByID, offeringIdentifier: offering.identifier)
        }

        guard !availablePackages.isEmpty else {
            let apiKeyValidationResult = self.systemInfo.apiKeyValidationResult
            #if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION && !DEBUG
            Logger.debug(Strings.offering.offering_empty(offeringIdentifier: offering.identifier,
                                                         apiKeyValidationResult: apiKeyValidationResult))
            #else
            Logger.warn(Strings.offering.offering_empty(offeringIdentifier: offering.identifier,
                                                        apiKeyValidationResult: apiKeyValidationResult))
            #endif
            return nil
        }

        let hasPaywallComponents = offering.hasPaywallComponents == true
            || (uiConfig != nil && offering.paywallComponents != nil)
        let paywallComponents: Offering.PaywallComponents? = {
            if shouldCreatePaywallComponents, let uiConfig, let paywallComponents = offering.paywallComponents {
                return .init(
                    uiConfig: uiConfig,
                    data: paywallComponents
                )
            }
            return nil
        }()

        let paywallDraftComponents: Offering.PaywallComponents? = {
            if shouldCreatePaywallComponents,
               let uiConfig,
               let paywallDraftComponents = offering.draftPaywallComponents {
                return .init(
                    uiConfig: uiConfig,
                    data: paywallDraftComponents
                )
            }
            return nil
        }()

        return Offering(identifier: offering.identifier,
                        serverDescription: offering.description,
                        metadata: offering.metadata.mapValues(\.asAny),
                        paywall: offering.paywall,
                        paywallComponents: paywallComponents,
                        hasPaywallComponents: hasPaywallComponents,
                        draftPaywallComponents: paywallDraftComponents,
                        availablePackages: availablePackages,
                        webCheckoutUrl: offering.webCheckoutUrl)
    }

    func createPackage(
        with data: OfferingsResponse.Offering.Package,
        productsByID: [String: StoreProduct],
        offeringIdentifier: String
    ) -> Package? {
        guard let product = productsByID[data.compoundProductIdentifier] else {
            return nil
        }

        return .init(package: data,
                     product: product,
                     offeringIdentifier: offeringIdentifier,
                     webCheckoutUrl: data.webCheckoutUrl)
    }

    func createPlacement(
        with data: OfferingsResponse.Placements?
    ) -> Offerings.Placements? {
        guard let data else {
            return nil
        }

        return .init(fallbackOfferingId: data.fallbackOfferingId,
                     offeringIdsByPlacement: data.offeringIdsByPlacement)
    }
}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension OfferingsFactory: @unchecked Sendable {}

// MARK: - Private

private extension Package {

    convenience init(
        package: OfferingsResponse.Offering.Package,
        product: StoreProduct,
        offeringIdentifier: String,
        webCheckoutUrl: URL?
    ) {
        self.init(identifier: package.identifier,
                  packageType: Package.packageType(from: package.identifier),
                  storeProduct: product,
                  offeringIdentifier: offeringIdentifier,
                  webCheckoutUrl: webCheckoutUrl)
    }

}

private extension Offerings.Contents {

    /// Drops offerings-provided paywall component bodies from the retained/cacheable response.
    /// When workflows are active, those component bodies are served by remote config instead, so
    /// retaining them here duplicates memory.
    func removingPaywallComponents() -> Self {
        let prunedOfferings = self.response.offerings.map { offering in
            var offering = offering
            offering.hasPaywallComponents = offering.hasPaywallComponents ?? (
                self.response.uiConfig != nil && offering.paywallComponents != nil
            )
            offering.paywallComponents = nil
            offering.draftPaywallComponents = nil
            return offering
        }
        let response = OfferingsResponse(
            currentOfferingId: self.response.currentOfferingId,
            offerings: prunedOfferings,
            placements: self.response.placements,
            targeting: self.response.targeting,
            uiConfig: self.response.uiConfig
        )

        var contents = self
        contents.response = response
        return contents
    }

}
