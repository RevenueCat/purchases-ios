//
//  PurchaserInfoHelperTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest
@testable import Purchases

class PurchaserInfoHelperTests: XCTestCase {
    let dateFormatter = DateFormatter()

    let dict = [
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
            ]]
    ]

    override func setUp() {
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }

    func testNonSubscriptionsList() {
        let list = PurchaserInfoHelper.nonConsumableTransactionsList(withNonSubscriptionsDictionary: dict, dateFormatter: dateFormatter)
        expect { list.count }.to(equal(4))
    }

    func testNonSubscriptionsMap() {
        let list = PurchaserInfoHelper.nonConsumableTransactionsMap(withNonSubscriptionsDictionary: dict, dateFormatter: dateFormatter)
        expect { list.count }.to(equal(2))
    }

    func testNonSubscriptionsMapTwo() {
        let list = PurchaserInfoHelper.nonConsumableTransactionsMap(withNonSubscriptionsDictionary: dict, dateFormatter: dateFormatter)
        let transactionsList = PurchaserInfoHelper.nonConsumableTransactionsList(withNonSubscriptionsTransactionsDictionary: list)
        expect { transactionsList.count }.to(equal(4))
    }
}
