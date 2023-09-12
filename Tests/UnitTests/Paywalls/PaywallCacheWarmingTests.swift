//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallCacheWarmingTests.swift
//
//  Created by Nacho Soto on 8/7/23.

import Nimble
@testable import RevenueCat
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
class PaywallCacheWarmingTests: TestCase {

    private var eligibilityChecker: MockTrialOrIntroPriceEligibilityChecker!
    private var imageFetcher: MockPaywallImageFetcher!
    private var cache: PaywallCacheWarmingType!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.eligibilityChecker = .init()
        self.imageFetcher = .init()
        self.cache = PaywallCacheWarming(introEligibiltyChecker: self.eligibilityChecker,
                                         imageFetcher: self.imageFetcher)
    }

    func testOfferingsWithNoPaywallsDoesNotCheckEligibility() async throws {
        await self.cache.warmUpEligibilityCache(
            offerings: try Self.createOfferings([
                Self.createOffering(
                    identifier: Self.offeringIdentifier,
                    paywall: nil,
                    products: [
                        (.monthly, "product_1")
                    ]
                )
            ])
        )

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == false
    }

    func testWarmsUpEligibilityCache() async throws {
        let paywall = try Self.loadPaywall("PaywallData-Sample1")
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: paywall,
                products: [
                    (.monthly, "product_1"),
                    (.weekly, "product_2")
                ]
            ),
            Self.createOffering(
                identifier: "offering_2",
                paywall: paywall,
                products: [
                    (.annual, "product_3")
                ]
            )
        ])

        await self.cache.warmUpEligibilityCache(offerings: offerings)

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == true
        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 1
        // Paywall filters packages so only `monthly` and `annual` should is used.
        expect(
            self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters
        ) == [
            "product_1",
            "product_3"
        ]

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.warming_up_eligibility_cache(products: ["product_1", "product_3"]),
            level: .debug
        )
    }

    func testOnlyWarmsUpEligibilityCacheOnce() async throws {
        let paywall = try Self.loadPaywall("PaywallData-Sample1")
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: paywall,
                products: [
                    (.monthly, "product_1")
                ]
            )
        ])

        await self.cache.warmUpEligibilityCache(offerings: offerings)
        await self.cache.warmUpEligibilityCache(offerings: offerings)

        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore) == true
        expect(self.eligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount) == 1

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.warming_up_eligibility_cache(products: ["product_1"]),
            level: .debug,
            expectedCount: 1
        )
    }

    func testWarmsUpImages() async throws {
        let paywall = try Self.loadPaywall("PaywallData-Sample1")
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: paywall,
                products: []
            )
        ])

        let expectedURLs: Set<String> = [
            "https://rc-paywalls.s3.amazonaws.com/header.jpg",
            "https://rc-paywalls.s3.amazonaws.com/background.jpg",
            "https://rc-paywalls.s3.amazonaws.com/icon.jpg"
        ]

        await self.cache.warmUpPaywallImagesCache(offerings: offerings)

        expect(self.imageFetcher.images) == expectedURLs
        expect(self.imageFetcher.imageDownloadRequestCount.value) == expectedURLs.count
    }

    func testOnlyWarmsUpImagesOnce() async throws {
        let paywall = try Self.loadPaywall("PaywallData-Sample1")
        let offerings = try Self.createOfferings([
            Self.createOffering(
                identifier: Self.offeringIdentifier,
                paywall: paywall,
                products: []
            )
        ])

        await self.cache.warmUpPaywallImagesCache(offerings: offerings)
        await self.cache.warmUpPaywallImagesCache(offerings: offerings)

        expect(self.imageFetcher.imageDownloadRequestCount.value) == 3
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension PaywallCacheWarmingTests {

    static func createOffering(
        identifier: String,
        paywall: PaywallData?,
        products: [(PackageType, String)]
    ) throws -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: identifier,
            paywall: paywall,
            availablePackages: products.map { packageType, productID in
                    .init(
                        identifier: Package.string(from: packageType)!,
                        packageType: packageType,
                        storeProduct: StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: productID)),
                        offeringIdentifier: identifier
                    )
            }
        )
    }

    static func createOfferings(_ offerings: [Offering]) throws -> Offerings {
        let offeringsURL = try XCTUnwrap(Self.bundle.url(forResource: "Offerings",
                                                         withExtension: "json",
                                                         subdirectory: "Fixtures"))

        let offeringsResponse = try OfferingsResponse.create(with: XCTUnwrap(Data(contentsOf: offeringsURL)))

        return .init(
            offerings: Set(offerings).dictionaryWithKeys(\.identifier),
            currentOfferingID: Self.offeringIdentifier,
            response: offeringsResponse
        )
    }

    static func loadPaywall(_ name: String) throws -> PaywallData {
        let paywallURL = try XCTUnwrap(Self.bundle.url(forResource: name,
                                                       withExtension: "json",
                                                       subdirectory: "Fixtures"))

        return try PaywallData.create(with: XCTUnwrap(Data(contentsOf: paywallURL)))
    }

    static let bundle = Bundle(for: PaywallCacheWarmingTests.self)
    static let offeringIdentifier = "offering"

}

private final class MockPaywallImageFetcher: PaywallImageFetcherType {

    let downloadedImages: Atomic<Set<URL>> = .init([])
    let imageDownloadRequestCount: Atomic<Int> = .init(0)

    var images: Set<String> {
        return Set(self.downloadedImages.value.map(\.absoluteString))
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func downloadImage(_ url: URL) async throws {
        self.downloadedImages.modify { $0.insert(url) }
        self.imageDownloadRequestCount.modify { $0 += 1 }
    }

}
