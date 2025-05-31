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

    func createOfferings(from storeProductsByID: [String: StoreProduct],
                         webProductsResponse: WebProductsResponse?,
                         data: OfferingsResponse) -> Offerings? {
        let offerings: [String: Offering] = data
            .offerings
            .compactMap { offeringData in
                createOffering(from: storeProductsByID,
                               webProductsOffering: webProductsResponse?.offerings[offeringData.identifier],
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
        webProductsOffering: WebProductsResponse.Offering?,
        offering: OfferingsResponse.Offering,
        uiConfig: UIConfig?
    ) -> Offering? {
        var packageIds = Set(offering.packages.map(\.identifier))
        let packagesById = offering.packages.dictionaryWithKeys(\.identifier)
        if let webProductsOffering = webProductsOffering {
            packageIds.formUnion(webProductsOffering.packages.keys)
        }
        let availablePackages: [Package] = packageIds.compactMap { packageId in
            createPackage(with: packagesById[packageId],
                          productsByID: storeProductsByID,
                          webProductsPackage: webProductsOffering?.packages[packageId],
                          offeringIdentifier: offering.identifier)
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
                        availablePackages: availablePackages,
                        webCheckoutUrl: offering.webCheckoutUrl)
    }

    func createPackage(
        with data: OfferingsResponse.Offering.Package?,
        productsByID: [String: StoreProduct],
        webProductsPackage: WebProductsResponse.Package?,
        offeringIdentifier: String
    ) -> Package? {
        guard let packageIdentifier = data?.identifier ?? webProductsPackage?.identifier else {
            return nil
        }
        var webProduct: StoreProduct?
        var webCheckoutUrl = webProductsPackage?.webCheckoutUrl

        if let webProductsPackage = webProductsPackage {
            webProduct = StoreProduct.from(webBillingProduct: webProductsPackage.productDetails)
        }
        var iosProduct: StoreProduct?
        if let data = data {
            iosProduct = productsByID[data.platformProductIdentifier]
        }
        guard let product = iosProduct ?? webProduct else {
            return nil
        }

        var storeProductByStoreRawValue: [Int: StoreProduct] = [:]
        if let iosProduct = iosProduct {
            storeProductByStoreRawValue[Store.appStore.rawValue] = iosProduct
        }
        if let webProduct = webProduct {
            storeProductByStoreRawValue[Store.rcBilling.rawValue] = webProduct
        }

        return .init(packageIdentifier: packageIdentifier,
                     product: product,
                     packageProducts: PackageProducts(nativeProduct: iosProduct, webBillingProduct: webProduct),
                     offeringIdentifier: offeringIdentifier,
                     webCheckoutUrl: webCheckoutUrl)
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
        packageIdentifier: String,
        product: StoreProduct,
        packageProducts: PackageProducts,
        offeringIdentifier: String,
        webCheckoutUrl: URL?
    ) {
        self.init(identifier: packageIdentifier,
                  packageType: Package.packageType(from: packageIdentifier),
                  storeProduct: product,
                  packageProducts: packageProducts,
                  presentedOfferingContext: .init(offeringIdentifier: offeringIdentifier),
                  webCheckoutUrl: webCheckoutUrl)
    }

}
