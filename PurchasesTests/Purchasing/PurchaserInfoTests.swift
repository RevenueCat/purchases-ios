//
//  PurchaserInfoTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Purchases

class EmptyPurchaserInfoTests: XCTestCase {
    let purchaserInfo = Purchases.PurchaserInfo.init(data: [AnyHashable : Any]())

    func testEmptyDataYieldsANilInfo() {
        expect(self.purchaserInfo).to(beNil())
    }
}

class BasicPurchaserInfoTests: XCTestCase {
    let validSubscriberResponse = [
        "request_date": "2018-10-19T02:40:36Z",
        "request_date_ms": 1563379533946,
        "subscriber": [
            "original_app_user_id": "app_user_id",
            "original_application_version": "2083",
            "first_seen": "2019-06-17T16:05:33Z",
            "non_subscriptions": [
                "onetime_purchase": [
                    [
                        "original_purchase_date": "1990-08-30T02:40:36Z",
                        "purchase_date": "1990-08-30T02:40:36Z"
                    ]
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
                    "expires_date" : "1990-08-30T02:40:36Z",
                    "product_identifier": "threemonth_freetrial",
                    "purchase_date": "1990-06-30T02:40:36Z"
                ],
                "forever_pro" : [
                    "expires_date" : nil,
                    "product_identifier": "onetime_purchase",
                    "purchase_date": "1990-08-30T02:40:36Z"
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

    var purchaserInfo: Purchases.PurchaserInfo?

    override func setUp() {
        super.setUp()

        purchaserInfo = Purchases.PurchaserInfo(data: validSubscriberResponse)
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

        expect(nonConsumables as NSSet).to(contain(["onetime_purchase"]))
    }

    func testOriginalApplicationVersionNull() {
        // TODO: why this test?
//        expect(self.purchaserInfo!.originalApplicationVersion).to(beNil())
    }

    func testOriginalApplicationVersion() {
        let purchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "original_application_version": "1.0",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(purchaserInfo!.originalApplicationVersion).to(equal("1.0"))
    }

    func testOriginalPurchaseDate() {
        let purchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(purchaserInfo!.originalPurchaseDate).to(equal(Date(timeIntervalSinceReferenceDate: 562288673)))
    }

    func testPreservesOriginalJSONSerializableObject() {
        let json = purchaserInfo?.jsonObject()
        let newInfo = Purchases.PurchaserInfo(data: json!)
        expect(newInfo).toNot(beNil())
    }

    func testTwoProductJson() {
        let json = try! JSONSerialization.jsonObject(with: validTwoProductsJSON.data(using: String.Encoding.utf8)!, options: [])
        let info = Purchases.PurchaserInfo(data: json as! [AnyHashable : Any])
        expect(info?.latestExpirationDate).toNot(beNil())
    }

    func testActiveEntitlementInfos() {
        let entitlements = purchaserInfo!.entitlements.active
        expect(entitlements.keys).to(contain("pro"));
        expect(entitlements.keys).toNot(contain("old_pro"));
    }
    
    func testRandomEntitlementInfos() {
        let entitlements = purchaserInfo!.entitlements.all
        expect(entitlements.keys).toNot(contain("random"));
    }

    func testGetExpirationDates() {
        let proDate = purchaserInfo!.expirationDate(forEntitlement: "pro")
        expect(proDate?.timeIntervalSince1970).to(equal(4123276836))
    }

    func testLifetimeSubscriptionsEntitlementInfos() {
        let entitlements = purchaserInfo!.entitlements.active
        expect(entitlements.keys).to(contain("forever_pro"));
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
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [
                    "onetime_purchase": [
                        [
                            "original_purchase_date": "1990-08-30T02:40:36Z",
                            "purchase_date": "1990-08-30T02:40:36Z"
                        ]
                    ],
                    "pro.3": [
                        [
                            "original_purchase_date": "1990-08-30T02:40:36Z",
                            "purchase_date": "1990-08-30T02:40:36Z"
                        ]
                    ]
                ],
                "subscriptions": [
                    "onemonth_freetrial": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "period_type": "normal"
                    ],
                    "threemonth_freetrial": [
                        "expires_date": "1990-08-30T02:40:36Z",
                        "period_type": "normal"
                    ],
                    "pro.1": [
                        "expires_date" : "2100-08-30T02:40:36Z",
                        "period_type": "normal"
                    ],
                    "pro.2": [
                        "expires_date" : "1990-08-30T02:40:36Z",
                        "period_type": "normal"
                    ]
                ],
                "entitlements": [
                    "pro" : [
                        "expires_date" : "2100-08-30T02:40:36Z",
                        "product_identifier": "pro.1",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ],
                    "old_pro" : [
                        "expires_date" : "1990-08-30T02:40:36Z",
                        "product_identifier": "pro.2",
                        "purchase_date": "1990-06-30T02:40:36Z"
                    ],
                    "forever_pro" : [
                        "expires_date" : nil,
                        "product_identifier": "pro.3",
                        "purchase_date": "1990-08-30T02:40:36Z"
                    ],
                ]
            ]
        ] as [String : Any]
        let purchaserInfoWithoutRequestData = Purchases.PurchaserInfo(data: response)

        let entitlements: [String : Purchases.EntitlementInfo] = purchaserInfoWithoutRequestData!.entitlements.active
        expect(entitlements["pro"]).toNot(beNil());
        expect(entitlements["old_pro"]).to(beNil());
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
        let purchaserInfoWithoutRequestData = Purchases.PurchaserInfo(data: response)
        let purchaseDate = purchaserInfoWithoutRequestData!.purchaseDate(forEntitlement: "pro")
        expect(purchaseDate).to(beNil())
    }
    
    func testEmptyInfosEqual() {
        let info1 = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        let info2 = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info1).to(equal(info2))
    }
    
    func testDifferentFetchDatesStillEqual() {
        let info1 = Purchases.PurchaserInfo(data: [
            "request_date": "2018-12-19T02:40:36Z",
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        let info2 = Purchases.PurchaserInfo(data: [
            "request_date": "2018-11-19T02:40:36Z",
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info1).to(equal(info2))
    }
    
    func testDifferentActiveEntitlementsNotEqual() {
        let info1 = Purchases.PurchaserInfo(data: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "subscriptions": [
                    "pro.1": [
                        "expires_date": "2018-12-19T02:40:36Z"
                    ]],
                "other_purchases": [:],
                "entitlements": [
                    "pro" : [
                        "expires_date": "2018-12-19T02:40:36Z",
                        "product_identifier": "pro.1"
                    ]
                ]
            ]])
        let info2 = Purchases.PurchaserInfo(data: [
            "request_date": "2018-11-19T02:40:36Z",
            "subscriber": [
                "subscriptions": [
                    "pro.1": [
                        "expires_date": "2018-12-19T02:40:36Z"
                    ]
                ],
                "other_purchases": [:],
                "entitlements": [
                    "pro" : [
                        "expires_date" : "2018-12-29T02:40:36Z",
                        "product_identifier": "pro.1"
                    ]
                ]
            ]])
        expect(info1).toNot(equal(info2))
    }
    
    func testDifferentEntitlementsNotEqual() {
        let info1 = Purchases.PurchaserInfo(data: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "subscriptions": [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2019-07-26T23:50:40Z",
                        "is_sandbox": true,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ],
                "non_subscriptions": [:],
                "entitlements": [
                    "pro" : [
                        "product_identifier": "monthly_freetrial",
                        "expires_date" : "2018-12-19T02:40:36Z",
                        "purchase_date": "2018-07-26T23:30:41Z"
                    ]
                ]
            ]])
        let info2 = Purchases.PurchaserInfo(data: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "subscriptions": [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": "2019-07-26T23:51:19Z",
                        "expires_date": "2019-07-26T23:50:40Z",
                        "is_sandbox": true,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ],
                "non_subscriptions": [:],
                "entitlements": [
                    "pro" : [
                        "product_identifier": "monthly_freetrial",
                        "expires_date" : "2018-12-19T02:40:36Z",
                        "purchase_date": "2018-07-26T23:30:41Z"
                    ]
                ]
            ]])
        expect(info1).toNot(equal(info2))
    }
    
    func testSameEntitlementsDifferentRequestDateEqual() {
        let info1 = Purchases.PurchaserInfo(data: [
            "request_date": "2018-12-21T02:40:36Z",
            "subscriber": [
                "subscriptions": [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2019-07-26T23:50:40Z",
                        "is_sandbox": true,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ],
                "non_subscriptions": [:],
                "entitlements": [
                    "pro" : [
                        "product_identifier": "monthly_freetrial",
                        "expires_date" : "2018-12-19T02:40:36Z",
                        "purchase_date": "2018-07-26T23:30:41Z"
                    ]
                ]
            ]])
        let info2 = Purchases.PurchaserInfo(data: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "subscriptions": [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2019-07-26T23:50:40Z",
                        "is_sandbox": true,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ],
                "non_subscriptions": [:],
                "entitlements": [
                    "pro" : [
                        "product_identifier": "monthly_freetrial",
                        "expires_date" : "2018-12-19T02:40:36Z",
                        "purchase_date": "2018-07-26T23:30:41Z"
                    ]
                ]
            ]])
        expect(info1).to(equal(info2))
    }

}
