//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPreviewResourcesLoader.swift
//
//  Created by Chris Vasselli on 2025/07/09.

import Foundation
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI

enum PaywallPreviewResourcesError: Error {
    case noValidResourceDirectories
    case couldNotReadOfferingsFile
    case failedToConvertJSONToData
    case failedToDecodeOfferings
    case couldNotParsePackagesData
    case failedToDecodePackages
}

class PaywallPreviewResourcesLoader {
    struct PackageData: Decodable {
        let packages: [OfferingsResponse.Offering.Package]
    }

    private var baseResourcesURL: URL
    private var offerings: [String: Offering] = [:]

    init(baseResourcesURL: URL) throws {
        self.baseResourcesURL = baseResourcesURL

        self.offerings = try loadOfferings()
    }

    var allOfferings: [Offering] {
        return Array(offerings.values)
    }

    private func loadOfferings() throws -> [String: Offering] {
        var result: [String: Offering] = [:]
        let resourceDirectories = (try? FileManager.default.contentsOfDirectory(
            at: baseResourcesURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ))?.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        } ?? []

        if resourceDirectories.isEmpty {
            throw PaywallPreviewResourcesError.noValidResourceDirectories
        }

        for resourceURL in resourceDirectories {
            let resource = resourceURL.lastPathComponent
            let offeringsFileName = "offerings.json"

            let packagesPath = baseResourcesURL
                .appendingPathComponent("packages.json")

            let offeringsPath = baseResourcesURL
                .appendingPathComponent(resource)
                .appendingPathComponent(offeringsFileName)

            let originalImagesURL = "https://assets.pawwalls.com"
            let replacementImagesURL = baseResourcesURL
                .appendingPathComponent(resource)
                .appendingPathComponent("pawwalls")
                .appendingPathComponent("assets")
                .absoluteString
            let originalIconsURL = "https://icons.pawwalls.com"
            let replacementIconsURL = baseResourcesURL
                .appendingPathComponent(resource)
                .appendingPathComponent("pawwalls")
                .appendingPathComponent("icons")
                .absoluteString

            // Read original file as String
            guard let offeringsRawString = try? String(contentsOf: offeringsPath) else {
                throw PaywallPreviewResourcesError.couldNotReadOfferingsFile
            }

            // Replace URLs
            let modifiedJSON = offeringsRawString
                .replacingOccurrences(of: originalImagesURL, with: replacementImagesURL)
                .replacingOccurrences(of: originalIconsURL, with: replacementIconsURL)

            // Decode updated JSON
            guard let modifiedData = modifiedJSON.data(using: .utf8) else {
                throw PaywallPreviewResourcesError.failedToConvertJSONToData
            }
            guard let offeringsResponse = try? JSONDecoder.default.decode(
                OfferingsResponse.self, from: modifiedData
            ) else {
                throw PaywallPreviewResourcesError.failedToDecodeOfferings
            }

            // Read and decode or print contents
            guard let packagesData = try? Data(contentsOf: packagesPath) else {
                throw PaywallPreviewResourcesError.couldNotParsePackagesData
            }
            guard let packages = try? JSONDecoder.default.decode(PackageData.self, from: packagesData) else {
                throw PaywallPreviewResourcesError.failedToDecodePackages
            }

            let offeringsWithPackages = offeringsResponse.offerings.map { offering in
                return OfferingsResponse.Offering(
                    identifier: offering.identifier,
                    description: offering.description,
                    packages: packages.packages,
                    paywallComponents: offering.paywallComponents,
                    draftPaywallComponents: offering.draftPaywallComponents,
                    webCheckoutUrl: offering.webCheckoutUrl
                )
            }

            let offeringsResponseWithPackages = OfferingsResponse(
                currentOfferingId: offeringsResponse.currentOfferingId,
                offerings: offeringsWithPackages,
                placements: offeringsResponse.placements,
                targeting: offeringsResponse.targeting,
                uiConfig: offeringsResponse.uiConfig
            )

            let systemInfo = SystemInfo(
                platformInfo: nil,
                finishTransactions: true,
                apiKey: "preview_api_key",
                preferredLocalesProvider: .init(preferredLocaleOverride: nil)
            )
            // Mock products for the preview offerings. Prices, subscription periods, and
            // the single introductory offer ($1.99 for 1 week) are kept in sync with the
            // web/dashboard preview tables so the rendering-validation screenshots show the
            // same products, prices, and offers across platforms.
            let storeProductsByID = Self.previewStoreProductsByID()

            let offerings = OfferingsFactory(systemInfo: systemInfo).createOfferings(
                from: storeProductsByID,
                contents: Offerings.Contents(response: offeringsResponseWithPackages,
                                             httpResponseOriginalSource: .mainServer),
                loadedFromDiskCache: false
            )

            result.merge(offerings!.all)
        }

        return result
    }

    // MARK: - Preview products

    private static let previewLocale = Locale(identifier: "en_US")

    /// A single introductory offer ($1.99 for 1 week) attached to every subscription.
    /// Matches the offer values in the web/dashboard preview variable tables and makes
    /// the products intro-offer eligible so offer-gated UI renders.
    private static func introductoryOffer() -> TestStoreProductDiscount {
        return TestStoreProductDiscount(
            identifier: "intro_offer",
            price: 1.99,
            localizedPriceString: "$1.99",
            paymentMode: .payUpFront,
            subscriptionPeriod: .init(value: 1, unit: .week),
            numberOfPeriods: 1,
            type: .introductory
        )
    }

    private static func subscriptionProduct(
        productIdentifier: String,
        title: String,
        price: Decimal,
        localizedPriceString: String,
        subscriptionPeriod: SubscriptionPeriod
    ) -> StoreProduct {
        return TestStoreProduct(
            localizedTitle: title,
            price: price,
            currencyCode: "USD",
            localizedPriceString: localizedPriceString,
            productIdentifier: productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: title,
            subscriptionPeriod: subscriptionPeriod,
            introductoryDiscount: introductoryOffer(),
            locale: previewLocale
        ).toStoreProduct()
    }

    /// Mock products keyed by both the base product identifier and the compound
    /// "product:plan" identifier, so packages resolve whether or not packages.json
    /// specifies a billing plan identifier.
    private static func previewStoreProductsByID() -> [String: StoreProduct] {
        let lifetime = TestStoreProduct(
            localizedTitle: "Lifetime",
            price: 119.99,
            currencyCode: "USD",
            localizedPriceString: "$119.99",
            productIdentifier: "com.revenuecat.lifetime_product",
            productType: .nonConsumable,
            localizedDescription: "Lifetime",
            locale: previewLocale
        ).toStoreProduct()

        let weekly = subscriptionProduct(
            productIdentifier: "com.revenuecat.weekly_product",
            title: "Weekly",
            price: 2.99,
            localizedPriceString: "$2.99",
            subscriptionPeriod: .init(value: 1, unit: .week)
        )
        let monthly = subscriptionProduct(
            productIdentifier: "com.revenuecat.monthly_product",
            title: "Monthly",
            price: 9.99,
            localizedPriceString: "$9.99",
            subscriptionPeriod: .init(value: 1, unit: .month)
        )
        let bimonthly = subscriptionProduct(
            productIdentifier: "com.revenuecat.bimonthly_product",
            title: "2 Months",
            price: 17.99,
            localizedPriceString: "$17.99",
            subscriptionPeriod: .init(value: 2, unit: .month)
        )
        let quarterly = subscriptionProduct(
            productIdentifier: "com.revenuecat.quarterly_product",
            title: "3 Months",
            price: 24.99,
            localizedPriceString: "$24.99",
            subscriptionPeriod: .init(value: 3, unit: .month)
        )
        let semester = subscriptionProduct(
            productIdentifier: "com.revenuecat.semester_product",
            title: "6 Months",
            price: 39.99,
            localizedPriceString: "$39.99",
            subscriptionPeriod: .init(value: 6, unit: .month)
        )
        let annual = subscriptionProduct(
            productIdentifier: "com.revenuecat.annual_product",
            title: "Annual",
            price: 69.99,
            localizedPriceString: "$69.99",
            subscriptionPeriod: .init(value: 1, unit: .year)
        )

        return [
            "com.revenuecat.lifetime_product": lifetime,
            "com.revenuecat.weekly_product": weekly,
            "com.revenuecat.weekly_product:p1w": weekly,
            "com.revenuecat.monthly_product": monthly,
            "com.revenuecat.monthly_product:p1m": monthly,
            "com.revenuecat.bimonthly_product": bimonthly,
            "com.revenuecat.bimonthly_product:p2m": bimonthly,
            "com.revenuecat.quarterly_product": quarterly,
            "com.revenuecat.quarterly_product:p3m": quarterly,
            "com.revenuecat.semester_product": semester,
            "com.revenuecat.semester_product:p6m": semester,
            "com.revenuecat.annual_product": annual,
            "com.revenuecat.annual_product:p1y": annual
        ]
    }

}
