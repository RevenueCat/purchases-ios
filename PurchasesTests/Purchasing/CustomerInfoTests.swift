//
//  CustomerInfoTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Foundation
import XCTest
import Nimble

@testable import RevenueCat

class EmptyCustomerInfoTests: XCTestCase {
    let customerInfo = CustomerInfo(testData: [String : Any]())

    func testEmptyDataYieldsANilInfo() {
        expect(self.customerInfo).to(beNil())
    }
}

class BasicCustomerInfoTests: XCTestCase {
    let validSubscriberResponse: [String: Any] = [
        "request_date": "2018-10-19T02:40:36Z",
        "request_date_ms": Int64(1563379533946),
        "subscriber": [
            "original_app_user_id": "app_user_id",
            "original_application_version": "2083",
            "first_seen": "2019-06-17T16:05:33Z",
            "non_subscriptions": [
                "onetime_purchase": [
                    [
                        "id": "d6c007ba74",
                        "is_sandbox": true,
                        "original_purchase_date": "1990-08-30T02:40:36Z",
                        "purchase_date": "1990-08-30T02:40:36Z",
                        "store": "play_store"
                    ]
                ]
            ],
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2100-08-30T02:40:36Z",
                    "period_type": "normal",
                    "is_sandbox": false
                ],
                "threemonth_freetrial": [
                    "period_type": "normal",
                    "purchase_date": "2018-05-20T06:24:50Z",
                    "expires_date": "2018-08-30T02:40:36Z"
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
    ]

    let validTwoProductsJSON = "{" +
            "\"request_date\": \"2018-05-20T06:24:50Z\"," +
            "\"subscriber\": {" +
            "\"first_seen\": \"2018-05-20T06:24:50Z\"," +
            "\"original_application_version\": \"1.0\"," +
            "\"original_app_user_id\": \"abcd\"," +
            "\"other_purchases\": {}," +
            "\"subscriptions\":{" +
                "\"product_a\": {\"expires_date\": \"2018-05-27T06:24:50Z\",\"period_type\": \"normal\"}," +
                "\"product_b\": {\"expires_date\": \"2018-05-27T05:24:50Z\",\"period_type\": \"normal\"}" +
            "}}}";

    var customerInfo: CustomerInfo?

    override func setUp() {
        super.setUp()

        customerInfo = CustomerInfo(testData: validSubscriberResponse)
    }

    func testParsesSubscriptions() {
        expect(self.customerInfo).toNot(beNil())
    }

    func testParsesExpirationDate() throws {
        let customerInfo = try XCTUnwrap(self.customerInfo)
        let expireDate = try XCTUnwrap(customerInfo.expirationDate(forProductIdentifier: "onemonth_freetrial"))
        expect(expireDate.timeIntervalSince1970).to(equal(4123276836))
    }

    func testListActiveSubscriptions() {
        XCTAssertEqual(Set(["onemonth_freetrial"]), customerInfo!.activeSubscriptions)
    }

    func testAllPurchasedProductIdentifier() {
        let allPurchased = customerInfo!.allPurchasedProductIdentifiers

        expect(allPurchased).to(equal(Set(["onemonth_freetrial", "threemonth_freetrial", "onetime_purchase"])))
    }

    func testLatestExpirationDateHelper() {
        let latestExpiration = customerInfo!.latestExpirationDate

        expect(latestExpiration).toNot(beNil())

        expect(latestExpiration).to(equal(customerInfo!.expirationDate(forProductIdentifier: "onemonth_freetrial")))
    }

    func testParsesOtherPurchases() {
        let nonConsumables = customerInfo!.nonSubscriptionTransactions
        expect(nonConsumables.count).to(equal(1))

        expect(nonConsumables[0].productId).to(equal("onetime_purchase"))
    }

    @available(*, deprecated) // Ignore deprecation warnings
    func testDeprecatedParsesOtherPurchases() {
        let nonConsumables = customerInfo!.nonConsumablePurchases
        expect(nonConsumables.count).to(equal(1))

        expect(nonConsumables).to(contain(["onetime_purchase"]))
    }

    func testOriginalApplicationVersionNilIfNotPresent() {
        let customerInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(customerInfo!.originalApplicationVersion).to(beNil())
    }

    func testOriginalApplicationVersionNilIfNull() {
        let customerInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": NSNull()
            ]])
        expect(customerInfo!.originalApplicationVersion).to(beNil())
    }

    func testOriginalApplicationVersion() {
        let customerInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "original_application_version": "1.0",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(customerInfo!.originalApplicationVersion).to(equal("1.0"))
    }

    func testOriginalPurchaseDate() {
        let customerInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_application_version": "1.0",
                "original_app_user_id": "app_user_id",
                "original_purchase_date": "2018-10-26T23:17:53Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(customerInfo!.originalPurchaseDate).to(equal(Date(timeIntervalSinceReferenceDate: 562288673)))
    }


    func testManagementURLNullIfNotPresent() {
        let customerInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(customerInfo!.managementURL).to(beNil())
    }

    func testManagementURLIsPresentWithValidURL() {
        let customerInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "management_url": "https://apple.com/manage_subscription",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(customerInfo!.managementURL).toNot(beNil())
        expect(customerInfo!.managementURL!.absoluteString) == "https://apple.com/manage_subscription"
    }

    func testManagementURLIsNullWithInvalidURL() {
        var customerInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "management_url": "this isnt' a URL!",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_app_user_id": "",
            ]])
        expect(customerInfo!.managementURL).to(beNil())

        customerInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "management_url": 68546984,
                "original_app_user_id": "",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:],
                "other_purchases": [:],
            ]])
        expect(customerInfo!.managementURL).to(beNil())

    }

    func testPreservesOriginalJSONSerializableObject() {
        let json = customerInfo?.jsonObject()
        let newInfo = CustomerInfo(testData: json!)
        expect(newInfo).toNot(beNil())
    }

    func testTwoProductJson() throws {
        let json = try JSONSerialization.jsonObject(with: validTwoProductsJSON.data(using: String.Encoding.utf8)!, options: [])
        let info = CustomerInfo(testData: json as! [String : Any])
        expect(info?.latestExpirationDate).toNot(beNil())
    }

    func testActiveEntitlementInfos() {
        let entitlements = customerInfo!.entitlements.active
        expect(entitlements.keys).to(contain("pro"));
        expect(entitlements.keys).toNot(contain("old_pro"));
    }
    
    func testRandomEntitlementInfos() {
        let entitlements = customerInfo!.entitlements.all
        expect(entitlements.keys).toNot(contain("random"));
    }

    func testGetExpirationDates() {
        let proDate = customerInfo!.expirationDate(forEntitlement: "pro")
        expect(proDate?.timeIntervalSince1970).to(equal(4123276836))
    }

    func testLifetimeSubscriptionsEntitlementInfos() {
        let entitlements = customerInfo!.entitlements.active
        expect(entitlements.keys).to(contain("forever_pro"));
    }

    func testExpirationLifetime() {
        expect(self.customerInfo!.expirationDate(forEntitlement: "forever_pro")).to(beNil())
    }

    func testRequestDate() {
        expect(self.customerInfo!.requestDate).toNot(beNil())
    }

    func testIfRequestDateIsNilUsesCurrentTime() {
        let response = [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [
                    "onetime_purchase": [
                        [
                            "id": "d6c007ba74",
                            "original_purchase_date": "1990-08-30T02:40:36Z",
                            "purchase_date": "1990-08-30T02:40:36Z", 
                            "is_sandbox": true,
                            "store": "play_store"
                        ]
                    ],
                    "pro.3": [
                        [
                            "id": "d6c007ba75",
                            "original_purchase_date": "1990-08-30T02:40:36Z",
                            "purchase_date": "1990-08-30T02:40:36Z",
                            "is_sandbox": true,
                            "store": "play_store"
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
        let customerInfoWithoutRequestData = CustomerInfo(testData: response)

        let entitlements: [String : EntitlementInfo] = customerInfoWithoutRequestData!.entitlements.active
        expect(entitlements["pro"]).toNot(beNil());
        expect(entitlements["old_pro"]).to(beNil());
    }

    func testPurchaseDateForEntitlement() throws {
        let customerInfo = try XCTUnwrap(self.customerInfo)
        let purchaseDate = customerInfo.purchaseDate(forEntitlement: "pro")
        expect(purchaseDate).to(equal(Date(timeIntervalSinceReferenceDate: 562288673)))
    }

    func testPurchaseDateForProductIdentifier() throws {
        let customerInfo = try XCTUnwrap(self.customerInfo)
        let purchaseDate = try XCTUnwrap(customerInfo.purchaseDate(forProductIdentifier: "threemonth_freetrial"))
        expect(purchaseDate) == Date(timeIntervalSince1970: 1526797490)
    }

    func testPurchaseDateEmpty() {
        let response = [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
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
        let customerInfoWithoutRequestData = CustomerInfo(testData: response)
        let purchaseDate = customerInfoWithoutRequestData!.purchaseDate(forEntitlement: "pro")
        expect(purchaseDate).to(beNil())
    }
    
    func testEmptyInfosEqual() {
        let info1 = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        let info2 = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info1).to(equal(info2))
    }
    
    func testDifferentFetchDatesStillEqual() {
        let info1 = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        let info2 = CustomerInfo(testData: [
            "request_date": "2018-11-19T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info1).to(equal(info2))
    }
    
    func testDifferentActiveEntitlementsNotEqual() {
        let info1 = CustomerInfo(testData: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
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
        let info2 = CustomerInfo(testData: [
            "request_date": "2018-11-19T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
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
        let info1 = CustomerInfo(testData: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
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
        let info2 = CustomerInfo(testData: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
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
        let info1 = CustomerInfo(testData: [
            "request_date": "2018-12-21T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
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
        let info2 = CustomerInfo(testData: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
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
    
    func testInitFailsIfNoRequestDate() {
        let info = CustomerInfo(testData: [
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "management_url": "https://apple.com/manage_subscription",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info).to(beNil())
    }
    
    func testInitFailsIfNoSubscriberOriginalAppUserId() {
        let info = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "management_url": "https://apple.com/manage_subscription",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info).to(beNil())
    }
    
    func testInitFailsIfNoSubscriber() {
        let info = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
           ])
        expect(info).to(beNil());
    }

    func testInitFailsIfNoSubscriberFirstSeen() {
        let info = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "management_url": "https://apple.com/manage_subscription",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info).to(beNil())
    }
    
    func testInitFailsIfMalformedRequestDate() {
        let info = CustomerInfo(testData: [
            "request_date": "2019-08-110:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        
        expect(info).to(beNil())
    }
    
    func testInitFailsIfMalformedFirstSeenDate() {
        let info = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-07-",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(info).to(beNil())
    }

    func testActiveSubscriptionsIncludesSubsWithNullExpirationDate() {
        let response = [
            "request_date": "2018-10-19T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [:],
                "subscriptions": [
                    "onemonth_freetrial": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "period_type": "normal"
                    ],
                    "twomonth_freetrial": [
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

        let info = CustomerInfo(testData: response)
        XCTAssertEqual(Set(["onemonth_freetrial", "twomonth_freetrial"]), info!.activeSubscriptions)

    }

    func testAllPurchasedProductIdentifiersIncludesNullExpDate() {
        let response = [
            "request_date": "2018-10-19T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [:],
                "subscriptions": [
                    "onemonth_freetrial": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "period_type": "normal"
                    ],
                    "twomonth_freetrial": [
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

        let info = CustomerInfo(testData: response)
        XCTAssertEqual(Set(["onemonth_freetrial", "twomonth_freetrial", "threemonth_freetrial"]),
                       info!.allPurchasedProductIdentifiers)
    }

}

extension CustomerInfo {

    convenience init?(testData: [String: Any]) {
        do {
            try self.init(data: testData,
                          dateFormatter: ISO8601DateFormatter.default,
                          transactionsFactory: TransactionsFactory())
        } catch {
            let errorDescription = (error as? DescribableError)?.description ?? error.localizedDescription
            Logger.error("Caught error creating testData, this is probably expected, right? \(errorDescription).")
            return nil
        }
    }

}
