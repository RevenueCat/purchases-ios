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
                createOffering(from: storeProductsByID, offering: offeringData)
            }
            .dictionaryAllowingDuplicateKeys { $0.identifier }

        guard !offerings.isEmpty else {
            return nil
        }

        return Offerings(offerings: offerings, currentOfferingID: data.currentOfferingId)
    }

    func createOffering(
        from storeProductsByID: [String: StoreProduct],
        offering: OfferingsResponse.Offering
    ) -> Offering? {
        let availablePackages: [Package] = offering.packages.compactMap { package in
            createPackage(with: package, productsByID: storeProductsByID, offeringIdentifier: offering.identifier)
        }

        guard !availablePackages.isEmpty else {
            Logger.warn(Strings.offering.offering_empty(offeringIdentifier: offering.identifier))
            return nil
        }

        return Offering(identifier: offering.identifier,
                        serverDescription: offering.description,
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
