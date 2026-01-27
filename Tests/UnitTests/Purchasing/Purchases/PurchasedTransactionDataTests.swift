//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasedTransactionDataTests.swift
//
//  Created by RevenueCat.

import Nimble
import XCTest

@testable import RevenueCat

class PurchasedTransactionDataTests: TestCase {

    // MARK: - removingAttributionData

    func testRemovingAttributionDataRemovesPresentedOfferingContext() {
        let data = PurchasedTransactionData(
            presentedOfferingContext: .init(offeringIdentifier: "test_offering"),
            presentedPaywall: nil,
            unsyncedAttributes: nil,
            metadata: nil,
            aadAttributionToken: nil,
            storeCountry: nil
        )

        let result = data.removingAttributionData()

        expect(result.presentedOfferingContext).to(beNil())
    }

    func testRemovingAttributionDataRemovesPresentedPaywall() {
        let paywallEventCreationData = PaywallEvent.CreationData(
            id: UUID(),
            date: Date()
        )
        let paywallEventData = PaywallEvent.Data(
            paywallIdentifier: "test_paywall_id",
            offeringIdentifier: "test_offering",
            paywallRevision: 1,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false
        )
        let data = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: .impression(paywallEventCreationData, paywallEventData),
            unsyncedAttributes: nil,
            metadata: nil,
            aadAttributionToken: nil,
            storeCountry: nil
        )

        let result = data.removingAttributionData()

        expect(result.presentedPaywall).to(beNil())
    }

    func testRemovingAttributionDataPreservesNonAttributionProperties() {
        let attributes: SubscriberAttribute.Dictionary = [
            "attr_key": .init(withKey: "attr_key", value: "attr_value")
        ]
        let metadata = ["meta_key": "meta_value"]
        let token = "aad_token"
        let country = "ESP"
        let paywallEventCreationData = PaywallEvent.CreationData(
            id: UUID(),
            date: Date()
        )
        let paywallEventData = PaywallEvent.Data(
            paywallIdentifier: "test_paywall_id",
            offeringIdentifier: "offering",
            paywallRevision: 1,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false
        )

        let data = PurchasedTransactionData(
            presentedOfferingContext: .init(offeringIdentifier: "test_offering"),
            presentedPaywall: .impression(paywallEventCreationData, paywallEventData),
            unsyncedAttributes: attributes,
            metadata: metadata,
            aadAttributionToken: token,
            storeCountry: country
        )

        let result = data.removingAttributionData()

        // Attribution data should be removed
        expect(result.presentedOfferingContext).to(beNil())
        expect(result.presentedPaywall).to(beNil())

        // Non-attribution properties should be preserved
        expect(result.unsyncedAttributes).to(equal(attributes))
        expect(result.metadata).to(equal(metadata))
        expect(result.aadAttributionToken).to(equal(token))
        expect(result.storeCountry).to(equal(country))
    }

}
