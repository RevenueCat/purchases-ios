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

    func createOfferings(from storeProductsByID: [String: StoreProduct], data: OfferingsResponse) -> Offerings? {
        let offerings: [String: Offering] = data
            .offerings
            .compactMap { offeringData in
                createOffering(from: storeProductsByID,
                               offering: offeringData,
                               uiConfig: data.uiConfig)
            }
            .dictionaryAllowingDuplicateKeys { $0.identifier }

        guard !offerings.isEmpty else {
            return nil
        }

        return Offerings(offerings: offerings,
                         currentOfferingID: data.currentOfferingId,
                         placements: createPlacement(with: data.placements),
                         targeting: data.targeting.flatMap { .init(revision: $0.revision, ruleId: $0.ruleId) },
                         response: data)
    }

    func createOffering(
        from storeProductsByID: [String: StoreProduct],
        offering: OfferingsResponse.Offering,
        uiConfig: UIConfig?
    ) -> Offering? {
        let availablePackages: [Package] = offering.packages.compactMap { package in
            createPackage(with: package, productsByID: storeProductsByID, offeringIdentifier: offering.identifier)
        }

        guard !availablePackages.isEmpty else {
            Logger.warn(Strings.offering.offering_empty(offeringIdentifier: offering.identifier))
            return nil
        }

        let paywallComponents: Offering.PaywallComponents? = {
            if let uiConfig, let paywallComponents = offering.paywallComponents {
                return .init(
                    uiConfig: uiConfig,
                    data: paywallComponents
                )
            }
            return nil
        }()

        let paywallDraftComponents: Offering.PaywallComponents? = {
            if let uiConfig, let paywallDraftComponents = offering.draftPaywallComponents {
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
                        draftPaywallComponents: paywallDraftComponents,
                        availablePackages: availablePackages)
    }

    func createPackage(
        with data: OfferingsResponse.Offering.Package,
        productsByID: [String: StoreProduct],
        offeringIdentifier: String
    ) -> Package? {
        guard let product = productsByID[data.platformProductIdentifier] else {
            return nil
        }

        return .init(package: data,
                     product: product,
                     offeringIdentifier: offeringIdentifier)
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
        offeringIdentifier: String
    ) {
        self.init(identifier: package.identifier,
                  packageType: Package.packageType(from: package.identifier),
                  storeProduct: product,
                  offeringIdentifier: offeringIdentifier)
    }

}
