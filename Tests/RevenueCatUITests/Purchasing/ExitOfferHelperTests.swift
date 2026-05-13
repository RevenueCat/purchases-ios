//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExitOfferHelperTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ExitOfferHelperTests: TestCase {

    // MARK: - exitOffer(offeringId:from:)

    func testExitOfferReturnsOfferingWhenFound() {
        let target = Self.makeOffering(identifier: "exit_offering_a")
        let offerings = Self.makeOfferings([target, Self.makeOffering(identifier: "other")])

        let result = ExitOfferHelper.exitOffer(offeringId: "exit_offering_a", from: offerings)

        expect(result?.identifier) == "exit_offering_a"
    }

    func testExitOfferReturnsNilWhenNotFound() {
        let offerings = Self.makeOfferings([Self.makeOffering(identifier: "other")])

        let result = ExitOfferHelper.exitOffer(offeringId: "exit_offering_a", from: offerings)

        expect(result).to(beNil())
    }

    func testExitOfferLogsWarningWhenNotFound() {
        let offerings = Self.makeOfferings([])

        _ = ExitOfferHelper.exitOffer(offeringId: "missing_offering", from: offerings)

        self.logger.verifyMessageWasLogged("Exit offer offering 'missing_offering' not found",
                                           level: .warn)
    }

    // MARK: - fetchValidExitOffer(offeringId:) — guard path

    func testFetchValidExitOfferReturnsNilWhenPurchasesNotConfigured() async {
        // Purchases is not configured in unit tests by default.
        guard !Purchases.isConfigured else {
            throw XCTSkip("Purchases is already configured; cannot test the unconfigured guard")
        }

        let result = await ExitOfferHelper.fetchValidExitOffer(offeringId: "exit_offering_a")

        expect(result).to(beNil())
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ExitOfferHelperTests {

    static func makeOffering(identifier: String) -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: "Offering \(identifier)",
            metadata: [:],
            paywall: nil,
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

    static func makeOfferings(_ offerings: [Offering]) -> Offerings {
        return Offerings(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
            currentOfferingID: nil,
            placements: nil,
            targeting: nil,
            contents: .init(
                response: .init(
                    currentOfferingId: nil,
                    offerings: [],
                    placements: nil,
                    targeting: nil,
                    uiConfig: nil
                ),
                httpResponseOriginalSource: .mainServer
            ),
            loadedFromDiskCache: false
        )
    }

}

#endif
