//
//  PurchaserInfoTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Purchases

class EmptyPurchaserInfoTests: XCTestCase {
    let purchaserInfo = RCPurchaserInfo.init(data: [AnyHashable : Any]())

    func testEmptyDataYieldsANilInfo() {
        expect(self.purchaserInfo).to(beNil())
    }
}

class BasicPurchaerInfoTests: XCTestCase {
    let validSubscriberResponse = [
        "subscriber": [
            "other_purchases": [
                "onetime_purchase": [
                    "purchase_date": "1990-08-30T02:40:36Z"
                ]
            ],
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2100-08-30T02:40:36Z"
                ],
                "threemonth_freetrial": [
                    "expires_date": "1990-08-30T02:40:36Z"
                ]
            ],
            "entitlements": [
                "pro" : [
                    "expires_date" : "2100-08-30T02:40:36Z"
                ],
                "old_pro" : [
                    "expires_date" : "1990-08-30T02:40:36Z"
                ],
                "forever_pro" : [
                    "expires_date" : nil
                ],
            ]
        ]
    ]

    let validTwoProductsJSON = "{\"subscriber\": {\"original_application_version\": \"1.0\",\"other_purchases\": {},\"subscriptions\":{\"product_a\": {\"expires_date\": \"2018-05-27T06:24:50Z\",\"period_type\": \"normal\"},\"product_b\": {\"expires_date\": \"2018-05-27T05:24:50Z\",\"period_type\": \"normal\"}}}}";

    var purchaserInfo: RCPurchaserInfo?

    override func setUp() {
        super.setUp()

        purchaserInfo = RCPurchaserInfo.init(data: validSubscriberResponse)
    }

    func testParsesSubscriptions() {
        expect(self.purchaserInfo).toNot(beNil())
    }

    func testParsesExpirationDate() {
        let expireDate = purchaserInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")!
        expect(expireDate.timeIntervalSince1970).to(equal(4123276836))
    }

    func testListActiveSubscriptions() {
        XCTAssertEqual(Set(["onemonth_freetrial"]), purchaserInfo!.activeSubscriptions)
    }

    func testAllPurchasedProductIdentifier() {
        let allPurchased = purchaserInfo!.allPurchasedProductIdentifiers

        expect(allPurchased).to(equal(Set(["onemonth_freetrial", "threemonth_freetrial", "onetime_purchase"])))
    }

    func testLatestExpirationDateHelper() {
        let latestExpiration = purchaserInfo!.latestExpirationDate

        expect(latestExpiration).toNot(beNil())

        expect(latestExpiration).to(equal(purchaserInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")))
    }

    func testParsesOtherPurchases() {
        let nonConsumables = purchaserInfo!.nonConsumablePurchases
        expect(nonConsumables.count).to(equal(1))

        expect(nonConsumables).to(contain(["onetime_purchase"]))
    }

    func testOriginalApplicationVersionNull() {
        expect(self.purchaserInfo!.originalApplicationVersion).to(beNil())
    }

    func testOriginalApplicationVersion() {
        let purchaserInfo = RCPurchaserInfo(data: [
            "subscriber": [
                "original_application_version": "1.0",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(purchaserInfo!.originalApplicationVersion).to(equal("1.0"))
    }

    func testPreservesOriginalJSONSerializableObject() {
        let json = purchaserInfo?.jsonObject()
        let newInfo = RCPurchaserInfo(data: json!)
        expect(newInfo).toNot(beNil())
    }


    func testTwoProductJson() {
        let json = try! JSONSerialization.jsonObject(with: validTwoProductsJSON.data(using: String.Encoding.utf8)!, options: [])
        let info = RCPurchaserInfo(data: json as! [AnyHashable : Any])
        expect(info?.latestExpirationDate).toNot(beNil())
    }

    func testActiveEntitlements() {
        let entitlements = purchaserInfo!.activeEntitlements
        expect(entitlements).to(contain("pro"));
        expect(entitlements).toNot(contain("old_pro"));
    }

    func testRandomEntitlement() {
        let entitlements = purchaserInfo!.activeEntitlements
        expect(entitlements).toNot(contain("random"));
    }

    func testGetExpirationDates() {
        let proDate = purchaserInfo!.expirationDate(forEntitlement: "pro")
        expect(proDate?.timeIntervalSince1970).to(equal(4123276836))
    }

    func testLifetimeSubscriptions() {
        let entitlements = purchaserInfo!.activeEntitlements
        expect(entitlements).to(contain("forever_pro"));
    }
}
