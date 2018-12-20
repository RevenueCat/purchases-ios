//
//  PurchaserInfoTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2018 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Purchases

class EmptyPurchaserInfoTests: XCTestCase {
    let purchaserInfo = PurchaserInfo.init(data: [AnyHashable : Any]())

    func testEmptyDataYieldsANilInfo() {
        expect(self.purchaserInfo).to(beNil())
    }
}

class BasicPurchaserInfoTests: XCTestCase {
    let validSubscriberResponse = [
        "request_date": "2018-10-19T02:40:36Z",
        "subscriber": [
            "other_purchases": [
                "onetime_purchase": [
                    "purchase_date": "1990-08-30T02:40:36Z"
                ]
            ],
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2100-08-30T02:40:36Z",
                    "period_type": "normal"
                ],
                "threemonth_freetrial": [
                    "expires_date": "1990-08-30T02:40:36Z"
                ]
            ],
            "entitlements": [
                "pro" : [
                    "expires_date" : "2100-08-30T02:40:36Z",
                    "product_identifier": "onemonth_freetrial",
                    "purchase_date": "2018-10-26T23:17:53Z"
                ],
                "old_pro" : [
                    "expires_date" : "1990-08-30T02:40:36Z"
                ],
                "forever_pro" : [
                    "expires_date" : nil
                ],
            ]
        ]
    ] as [String : Any]

    let validTwoProductsJSON = "{" +
            "\"request_date\": \"2018-05-20T06:24:50Z\"," +
            "\"subscriber\": {" +
            "\"original_application_version\": \"1.0\"," +
            "\"other_purchases\": {}," +
            "\"subscriptions\":{" +
                "\"product_a\": {\"expires_date\": \"2018-05-27T06:24:50Z\",\"period_type\": \"normal\"}," +
                "\"product_b\": {\"expires_date\": \"2018-05-27T05:24:50Z\",\"period_type\": \"normal\"}" +
            "}}}";

    var purchaserInfo: PurchaserInfo?

    override func setUp() {
        super.setUp()

        purchaserInfo = PurchaserInfo(data: validSubscriberResponse)
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
        let purchaserInfo = PurchaserInfo(data: [
            "subscriber": [
                "original_application_version": "1.0",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(purchaserInfo!.originalApplicationVersion).to(equal("1.0"))
    }

    func testPreservesOriginalJSONSerializableObject() {
        let json = purchaserInfo?.jsonObject()
        let newInfo = PurchaserInfo(data: json!)
        expect(newInfo).toNot(beNil())
    }


    func testTwoProductJson() {
        let json = try! JSONSerialization.jsonObject(with: validTwoProductsJSON.data(using: String.Encoding.utf8)!, options: [])
        let info = PurchaserInfo(data: json as! [AnyHashable : Any])
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

    func testExpirationLifetime() {
        expect(self.purchaserInfo!.expirationDate(forEntitlement: "forever_pro")).to(beNil())
    }

    func testRequestDate() {
        expect(self.purchaserInfo!.requestDate).toNot(beNil())
    }

    func testIfRequestDateIsNilUsesCurrentTime() {
        let response = [
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
            ] as [String : Any]
        let purchaserInfoWithoutRequestData = PurchaserInfo(data: response)

        let entitlements = purchaserInfoWithoutRequestData!.activeEntitlements
        expect(entitlements).to(contain("pro"));
        expect(entitlements).toNot(contain("old_pro"));
    }

    func testPurchaseDate() {
        let purchaseDate = self.purchaserInfo!.purchaseDate(forEntitlement: "pro")
        expect(purchaseDate).to(equal(Date(timeIntervalSinceReferenceDate: 562288673)))
    }

    func testPurchaseDateEmpty() {
        let response = [
            "subscriber": [
                "other_purchases": [
                    "onetime_purchase": [
                        "expires_date": "1990-08-30T02:40:36Z"
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
        ] as [String : Any]
        let purchaserInfoWithoutRequestData = PurchaserInfo(data: response)
        let purchaseDate = purchaserInfoWithoutRequestData!.purchaseDate(forEntitlement: "pro")
        expect(purchaseDate).to(beNil())
    }
    
    func testEmptyInfosEqual() {
        let info1 = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        let info2 = PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info1).to(equal(info2))
    }

}
