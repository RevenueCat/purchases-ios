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

class TransactionsFactoryTests: TestCase {

    func testNonSubscriptionsIsCorrectlyCreated() throws {
        let nonSubscriptionTransactions = try TransactionsFactory.nonSubscriptionTransactions(
            withSubscriptionsData: Self.sampleTransactions
        )
        expect(nonSubscriptionTransactions).to(haveCount(5))

        for (productId, transactionsData) in Self.sampleTransactions {
            let filteredTransactions = nonSubscriptionTransactions
                .filter { $0.productIdentifier == productId }

            expect(filteredTransactions).to(haveCount(transactionsData.count))

            for dictionary in transactionsData {
                let revenueCatTransactionID = try XCTUnwrap(dictionary["id"] as? String)
                let storeTransactionID = try XCTUnwrap(dictionary["store_transaction_id"] as? String)

                expect(filteredTransactions).to(containElementSatisfying {
                    $0.transactionIdentifier == revenueCatTransactionID &&
                    $0.storeTransactionIdentifier == storeTransactionID
                })
            }
        }

    }

    func testNonSubscriptionsIsEmptyIfThereAreNoNonSubscriptions() {
        let list = TransactionsFactory.nonSubscriptionTransactions(withSubscriptionsData: [:])
        expect(list).to(beEmpty())
    }

}

private extension TransactionsFactoryTests {

    static let sampleTransactions: [String: [[String: Any]]] = [
        "100_coins": [
            [
                "id": "72c26cc69c",
                "store_transaction_id": "1",
                "is_sandbox": true,
                "original_purchase_date": "1990-08-30T02:40:36Z",
                "purchase_date": "2019-07-11T18:36:20Z",
                "store": "app_store"
            ],
            [
                "id": "6229b0bef1",
                "store_transaction_id": "2",
                "is_sandbox": true,
                "original_purchase_date": "2019-11-06T03:26:15Z",
                "purchase_date": "2019-11-06T03:26:15Z",
                "store": "play_store"
            ]
        ],
        "500_coins": [
            [
                "id": "d6c007ba74",
                "store_transaction_id": "3",
                "is_sandbox": true,
                "original_purchase_date": "2019-07-11T18:36:20Z",
                "purchase_date": "2019-07-11T18:36:20Z",
                "store": "play_store"
            ],
            [
                "id": "5b9ba226bc",
                "store_transaction_id": "4",
                "is_sandbox": true,
                "original_purchase_date": "2019-07-26T22:10:27Z",
                "purchase_date": "2019-07-26T22:10:27Z",
                "store": "app_store"
            ]
        ],
        "lifetime_access": [
            [
                "id": "d6c097ba74",
                "store_transaction_id": "5",
                "is_sandbox": true,
                "original_purchase_date": "2018-07-11T18:36:20Z",
                "purchase_date": "2018-07-11T18:36:20Z",
                "store": "app_store"
            ]
        ]
    ]

}

private extension TransactionsFactory {

    static func nonSubscriptionTransactions(
        withSubscriptionsData data: [String: Any]
    ) throws -> [NonSubscriptionTransaction] {
        let data = try JSONSerialization.data(withJSONObject: data)
        let transactions: [String: [CustomerInfoResponse.Transaction]] = try JSONDecoder.default.decode(
            jsonData: data
        )

        return Self.nonSubscriptionTransactions(withSubscriptionsData: transactions)
    }

}
