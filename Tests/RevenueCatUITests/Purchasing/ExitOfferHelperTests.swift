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
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ExitOfferHelperTests: TestCase {

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

    func testExitOfferReturnsNilWhenOfferingIdMissing() {
        let offerings = Self.makeOfferings([])

        let result = ExitOfferHelper.exitOffer(offeringId: "missing_offering", from: offerings)

        expect(result).to(beNil())
    }

    func testValidExitOfferReturnsNilWhenExitOfferMatchesCurrentOffering() {
        let offerings = Self.makeOfferings([Self.makeOffering(identifier: "offering_a")])

        let result = ExitOfferHelper.validExitOffer(
            offeringId: "offering_a",
            currentOfferingId: "offering_a",
            from: offerings
        )

        expect(result).to(beNil())
        // validExitOffer is a pure function — no side effects — so it's safe to call on every
        // SwiftUI render; it never logs.
        self.logger.verifyMessageWasNotLogged(
            Strings.exitOfferSameAsCurrent,
            level: .warn,
            allowNoMessages: true
        )
    }

    func testValidExitOfferReturnsOfferingWhenDifferentFromCurrentOffering() {
        let offerings = Self.makeOfferings([
            Self.makeOffering(identifier: "offering_a"),
            Self.makeOffering(identifier: "exit_offering_a")
        ])

        let result = ExitOfferHelper.validExitOffer(
            offeringId: "exit_offering_a",
            currentOfferingId: "offering_a",
            from: offerings
        )

        expect(result?.identifier) == "exit_offering_a"
    }

}

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
