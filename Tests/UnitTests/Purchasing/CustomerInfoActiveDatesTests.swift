//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class CustomerInfoActiveDatesTests: BaseHTTPResponseTest {

    func testExtractPurchaseDatesMapsProductIdWithProductPlanIdentifier() {
        var googleStyleSubscription = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1000))
        googleStyleSubscription.productPlanIdentifier = "monthly"

        let subscriber = Self.makeSubscriber(
            subscriptions: ["pro_google": googleStyleSubscription]
        )
        let purchaseDates = CustomerInfo.extractPurchaseDates(subscriber)

        expect(purchaseDates["pro_google:monthly"]) == .init(timeIntervalSince1970: 1000)
        expect(purchaseDates["pro_google"]).to(beNil())
        expect(purchaseDates.keys.count).to(equal(1))
    }

    func testExtractPurchaseDatesMapsProductIdWithoutProductPlanIdentifier() {
        let iOSStyleSubscription = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1000))

        let subscriber = Self.makeSubscriber(
            subscriptions: ["pro": iOSStyleSubscription]
        )
        let purchaseDates = CustomerInfo.extractPurchaseDates(subscriber)

        expect(purchaseDates["pro"]) == .init(timeIntervalSince1970: 1000)
        expect(purchaseDates.keys.count).to(equal(1))
    }

    func testExtractPurchaseDatesForDuplicateMappedKeyUsesMostRecentPurchaseDate() {
        var purchaseWithPlan = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1000))
        purchaseWithPlan.productPlanIdentifier = "monthly"

        let purchaseWithoutPlan = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 2000))
        let iosStyleSubscription = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1500))

        let subscriber = Self.makeSubscriber(
            subscriptions: [
                "pro": purchaseWithPlan,
                "pro:monthly": purchaseWithoutPlan,
                "pro_ios": iosStyleSubscription
            ]
        )

        let purchaseDates = CustomerInfo.extractPurchaseDates(subscriber)
        expect(purchaseDates["pro:monthly"]) == .init(timeIntervalSince1970: 2000)
        expect(purchaseDates["pro"]).to(beNil())
        expect(purchaseDates["pro_ios"]) == .init(timeIntervalSince1970: 1500)
        expect(purchaseDates.count) == 2
    }

    func testExtractPurchaseDatesForDuplicateMappedKeyWithEqualDatesPrefersGoogleStyleProductID() {
        var purchaseWithPlan = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1000))
        purchaseWithPlan.productPlanIdentifier = "monthly"

        let googleStyleRawIDPurchase = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1000))
        let iosStyleSubscription = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1500))

        let subscriber = Self.makeSubscriber(
            subscriptions: [
                "pro": purchaseWithPlan,
                "pro:monthly": googleStyleRawIDPurchase,
                "pro_ios": iosStyleSubscription
            ]
        )

        let purchaseDates = CustomerInfo.extractPurchaseDates(subscriber)
        expect(purchaseDates["pro:monthly"]) == .init(timeIntervalSince1970: 1000)
        expect(purchaseDates["pro"]).to(beNil())
        expect(purchaseDates["pro_ios"]) == .init(timeIntervalSince1970: 1500)
    }

    func testExtractPurchaseDatesConsidersNonSubscriptionsWhenMappedKeyCollides() {
        var googleStyleSubscription = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1000))
        googleStyleSubscription.productPlanIdentifier = "monthly"
        let iosStyleSubscription = Self.makeSubscription(purchaseDate: .init(timeIntervalSince1970: 1200))

        let nonSubscriptionTransaction = Self.makeTransaction(purchaseDate: .init(timeIntervalSince1970: 3000))

        let subscriber = Self.makeSubscriber(
            subscriptions: [
                "pro": googleStyleSubscription,
                "pro_ios": iosStyleSubscription
            ],
            nonSubscriptions: ["pro:monthly": [nonSubscriptionTransaction]]
        )

        let purchaseDates = CustomerInfo.extractPurchaseDates(subscriber)
        expect(purchaseDates["pro:monthly"]) == .init(timeIntervalSince1970: 3000)
        expect(purchaseDates["pro"]).to(beNil())
        expect(purchaseDates["pro_ios"]) == .init(timeIntervalSince1970: 1200)
    }

    func testCreatingCustomerInfoFromFixtureWithDuplicateMappedProductKeysDoesNotCrash() throws {
        let response: CustomerInfoResponse = try Self.decodeFixture("CustomerInfoWithDuplicateMappedProductKeys")
        let data = try response.asJSONDictionary()

        expect { try CustomerInfo(data: data) }.toNot(throwError())

        let customerInfo = try CustomerInfo(data: data)
        expect(customerInfo.purchaseDate(forProductIdentifier: "rc_sub:monthly")) ==
        .init(timeIntervalSince1970: 1709251200)
        expect(customerInfo.purchaseDate(forProductIdentifier: "rc_sub")).to(beNil())
        expect(customerInfo.purchaseDate(forProductIdentifier: "pro_ios")) ==
        .init(timeIntervalSince1970: 1706745600)
    }

}

private extension CustomerInfoActiveDatesTests {

    static func makeSubscriber(
        subscriptions: [String: CustomerInfoResponse.Subscription] = [:],
        nonSubscriptions: [String: [CustomerInfoResponse.Transaction]] = [:]
    ) -> CustomerInfoResponse.Subscriber {
        return .init(
            originalAppUserId: "app_user_id",
            firstSeen: .init(timeIntervalSince1970: 0),
            subscriptions: subscriptions,
            nonSubscriptions: nonSubscriptions,
            entitlements: [:]
        )
    }

    static func makeSubscription(purchaseDate: Date) -> CustomerInfoResponse.Subscription {
        return .init(
            periodType: .normal,
            purchaseDate: purchaseDate,
            originalPurchaseDate: nil,
            expiresDate: nil,
            store: .playStore,
            isSandbox: false
        )
    }

    static func makeTransaction(purchaseDate: Date) -> CustomerInfoResponse.Transaction {
        return .init(
            purchaseDate: purchaseDate,
            originalPurchaseDate: nil,
            transactionIdentifier: nil,
            storeTransactionIdentifier: nil,
            store: .playStore,
            isSandbox: false
        )
    }

}
