//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesSyncAttributesAndOfferingsIfNeededTests.swift
//
//  Created by Lauren Burdock on 2/26/24.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesSyncAttributesAndOfferingsIfNeededTests: BasePurchasesTests {

    func testAttributesSyncedAndOfferingsFetched() throws {

        self.setupPurchases()
        let userID1 = "userID1"
        let userID2 = "userID2"
        let userID3 = "userID3"

        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "The Doors"),
            "song": SubscriberAttribute(withKey: "song", value: "Riders on the storm"),
            "album": SubscriberAttribute(withKey: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": SubscriberAttribute(withKey: "instrument", value: "Guitar"),
            "name": SubscriberAttribute(withKey: "name", value: "Robert Krieger")
        ]
        let userID3Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Dire Straits"),
            "song": SubscriberAttribute(withKey: "song", value: "Sultans of Swing"),
            "album": SubscriberAttribute(withKey: "album", value: "Dire Straits")
        ]
        let allAttributes: [String: [String: SubscriberAttribute]] = [
            userID1: userID1Attributes,
            userID2: userID2Attributes,
            userID3: userID3Attributes
        ]

        self.deviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:], data: .mockResponse))
        )

        let result: Offerings? = waitUntilValue { completed in
            self.purchases.syncAttributesAndOfferingsIfNeeded(completion: { offerings, error in
                completed(offerings)
            })
        }
        expect(result).toNot(beNil())
        expect(self.subscriberAttributesManager.invokedSetAttributesCount) == 1
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 1
    }
}
