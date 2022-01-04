//
//  CustomerInfoHelperTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Nimble
@testable import RevenueCat
import XCTest

class TransactionsFactoryTests: XCTestCase {

    let dateFormatter = DateFormatter()
    let transactionsFactory = TransactionsFactory()

    let sampleTransactions = [
        "100_coins": [
            [
                "id": "72c26cc69c",
                "is_sandbox": true,
                "original_purchase_date": "1990-08-30T02:40:36Z",
                "purchase_date": "2019-07-11T18:36:20Z",
                "store": "app_store"
            ], [
                "id": "6229b0bef1",
                "is_sandbox": true,
                "original_purchase_date": "2019-11-06T03:26:15Z",
                "purchase_date": "2019-11-06T03:26:15Z",
                "store": "play_store"
            ]],
        "500_coins": [
            [
                "id": "d6c007ba74",
                "is_sandbox": true,
                "original_purchase_date": "2019-07-11T18:36:20Z",
                "purchase_date": "2019-07-11T18:36:20Z",
                "store": "play_store"
            ], [
                "id": "5b9ba226bc",
                "is_sandbox": true,
                "original_purchase_date": "2019-07-26T22:10:27Z",
                "purchase_date": "2019-07-26T22:10:27Z",
                "store": "app_store"
            ]],
        "lifetime_access": [
            [
                "id": "d6c097ba74",
                "is_sandbox": true,
                "original_purchase_date": "2018-07-11T18:36:20Z",
                "purchase_date": "2018-07-11T18:36:20Z",
                "store": "app_store"
            ]]
    ]

    override func setUp() {
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }

    func testNonSubscriptionsIsCorrectlyCreated() {
        let nonSubscriptionTransactions = transactionsFactory.nonSubscriptionTransactions(
            withSubscriptionsData: sampleTransactions,
            dateFormatter: dateFormatter
        )
        expect(nonSubscriptionTransactions.count) == 5

        sampleTransactions.forEach { productId, transactionsData in
            let filteredTransactions = nonSubscriptionTransactions.filter { $0.productId == productId }
            expect(filteredTransactions.count) == transactionsData.count
            transactionsData.forEach { dictionary in
                guard let transactionId = dictionary["id"] as? String else { fatalError("incorrect dict format") }
                let containsTransaction = filteredTransactions.contains { $0.revenueCatId == transactionId }
                expect(containsTransaction) == true
            }
        }

    }

    func testNonSubscriptionsIsEmptyIfThereAreNoNonSubscriptions() {
        let list = transactionsFactory.nonSubscriptionTransactions(
            withSubscriptionsData: [:],
            dateFormatter: dateFormatter
        )
        expect(list).to(beEmpty())
    }

    func testBuildsCorrectlyEvenIfSomeTransactionsCantBeBuilt() {
        let subscriptionsData = [
            "lifetime_access": [
                [
                    "id": "d6c097ba74",
                    "is_sandbox": true,
                    "original_purchase_date": "2018-07-11T18:36:20Z",
                    "purchase_date": "2018-07-11T18:36:20Z",
                    "store": "app_store"
                ]
            ],
            "invalid_non_transaction": [
                [
                    "ioasgioaew": 0832
                ]
            ]
        ]

        let nonSubscriptionTransactions = transactionsFactory.nonSubscriptionTransactions(
            withSubscriptionsData: subscriptionsData,
            dateFormatter: dateFormatter
        )
        expect(nonSubscriptionTransactions.count) == 1
        expect(nonSubscriptionTransactions.first!.productId) == "lifetime_access"
    }

}
