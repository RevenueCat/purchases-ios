//
//  SubscriberInfoTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Purchases

class EmptySubscriberInfoTests: XCTestCase {
    let subscriberInfo = RCPurchaserInfo.init(data: [AnyHashable : Any]())

    func testEmptyDataYieldsANilInfo() {
        expect(RCPurchaserInfo.init(data: [AnyHashable : Any]())).to(beNil())
    }
}

class BasicSubscriberInfoTests: XCTestCase {
    let validSubscriberResponse = [
        "subscriber": [
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2100-08-30T02:40:36Z"
                ],
                "threemonth_freetrial": [
                    "expires_date": "1990-08-30T02:40:36Z"
                ]
            ]
        ]
    ]

    var subscriberInfo: RCPurchaserInfo?

    override func setUp() {
        super.setUp()

        subscriberInfo = RCPurchaserInfo.init(data: validSubscriberResponse)
    }

    func testParsesSubscriptions() {
        expect(self.subscriberInfo).toNot(beNil())
    }

    func testParsesExpirationDate() {
        let expireDate = subscriberInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")!
        expect(expireDate.timeIntervalSince1970).to(equal(4123276836))
    }

    func testListActiveSubscriptions() {
        XCTAssertEqual(Set(["onemonth_freetrial"]), subscriberInfo!.activeSubscriptions)
    }

    func testAllPurchasedProductIdentifier() {
        let allPurchased = subscriberInfo!.allPurchasedProductIdentifiers

        expect(allPurchased).to(equal(Set(["onemonth_freetrial", "threemonth_freetrial"])))
    }

    func testLatestExpirationDateHelper() {
        let latestExpiration = subscriberInfo!.latestExpirationDate

        expect(latestExpiration).toNot(beNil())

        expect(latestExpiration).to(equal(subscriberInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")))
    }
}
