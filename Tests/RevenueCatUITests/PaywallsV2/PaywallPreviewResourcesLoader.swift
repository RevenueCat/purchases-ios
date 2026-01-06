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
@testable import RevenueCat
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

            let offerings = OfferingsFactory().createOfferings(from: [
                "com.revenuecat.lifetime_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .week,
                    localizedTitle: "Lifeime"
                )),
                "com.revenuecat.annual_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .year,
                    localizedTitle: "Annual"
                )),
                "com.revenuecat.semester_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .month,
                    localizedTitle: "6 Month"
                )),
                "com.revenuecat.quarterly_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .week,
                    localizedTitle: "3 Month"
                )),
                "com.revenuecat.bimonthly_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .week,
                    localizedTitle: "2 Month"
                )),
                "com.revenuecat.monthly_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .month,
                    localizedTitle: "Monthly"
                )),
                "com.revenuecat.weekly_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .week,
                    localizedTitle: "Weekly"
                ))
            ], contents: Offerings.Contents(response: offeringsResponseWithPackages,
                                            httpResponseOriginalSource: .mainServer),
                                                               loadedFromDiskCache: false)

            result.merge(offerings!.all)
        }

        return result
    }

}
