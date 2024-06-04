//
//  CustomerInfoTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class EmptyCustomerInfoTests: TestCase {

    func testEmptyDataFails() throws {
        expect(try CustomerInfo(data: [:])).to(throwError(ErrorCode.customerInfoError))
    }

}

class BasicCustomerInfoTests: TestCase {

    private static func date(withDaysAgo days: Int) throws -> Date {
        return try XCTUnwrap(Calendar.current.date(byAdding: .day, value: days, to: Date()))
    }

    private static let expiredSubscriptionDate = ISO8601DateFormatter.default.string(
        // swiftlint:disable:next force_try
        from: try! BasicCustomerInfoTests.date(withDaysAgo: -1)
    )
    static let validSubscriberResponse: [String: Any] = [
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
                        "store_transaction_id": "340001090153249",
                        "is_sandbox": true,
                        "original_purchase_date": "1990-08-30T02:40:36Z",
                        "purchase_date": "1990-08-30T02:40:36Z",
                        "store": "play_store"
                    ] as [String: Any]
                ]
            ] as [String: Any],
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2100-08-30T02:40:36Z",
                    "period_type": "normal",
                    "is_sandbox": false
                ] as [String: Any],
                "gold": [
                    "expires_date": "2100-07-30T02:40:36Z",
                    "period_type": "normal",
                    "is_sandbox": false,
                    "product_plan_identifier": "monthly",
                    "purchase_date": "2018-05-20T06:24:50Z"
                ],
                "onemonth": [
                    "expires_date": BasicCustomerInfoTests.expiredSubscriptionDate,
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
                "pro": [
                    "expires_date": "2100-08-30T02:40:36Z",
                    "product_identifier": "onemonth_freetrial",
                    "purchase_date": "2018-10-26T23:17:53Z"
                ],
                "pro_google_play": [
                    "expires_date": "2100-08-30T02:40:36Z",
                    "product_identifier": "onemonth_freetrial",
                    "purchase_date": "2018-10-26T23:17:53Z"
                ],
                "expired_pro": [
                    "expires_date": BasicCustomerInfoTests.expiredSubscriptionDate,
                    "product_identifier": "onemonth",
                    "purchase_date": "1990-06-30T02:40:36Z"
                ],
                "old_pro": [
                    "expires_date": "1990-08-30T02:40:36Z",
                    "product_identifier": "threemonth_freetrial",
                    "purchase_date": "1990-06-30T02:40:36Z"
                ],
                "forever_pro": [
                    "expires_date": nil,
                    "product_identifier": "onetime_purchase",
                    "purchase_date": "1990-08-30T02:40:36Z"
                ]
            ]
        ] as [String: Any]
    ]

    static let validTwoProductsJSON = "{" +
            "\"request_date\": \"2018-05-20T06:24:50Z\"," +
            "\"subscriber\": {" +
            "\"first_seen\": \"2018-05-20T06:24:50Z\"," +
            "\"original_application_version\": \"1.0\"," +
            "\"original_app_user_id\": \"abcd\"," +
            "\"other_purchases\": {}," +
            "\"subscriptions\":{" +
                "\"product_a\": {\"expires_date\": \"2018-05-27T06:24:50Z\",\"period_type\": \"normal\"}," +
                "\"product_b\": {\"expires_date\": \"2018-05-27T05:24:50Z\",\"period_type\": \"normal\"}" +
            "}}}"

    private var customerInfo: CustomerInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.customerInfo = try CustomerInfo(data: Self.validSubscriberResponse)
    }

    func testParsesExpirationDate() throws {
        let expireDate = try XCTUnwrap(self.customerInfo.expirationDate(forProductIdentifier: "onemonth_freetrial"))
        expect(expireDate.timeIntervalSince1970) == 4123276836
    }

    func testListActiveSubscriptions() {
        expect(self.customerInfo.activeSubscriptions) == ["onemonth_freetrial", "gold:monthly"]
    }

    func testAllPurchasedProductIdentifier() {
        let allPurchased = self.customerInfo.allPurchasedProductIdentifiers

        expect(allPurchased) == ["onemonth", "onemonth_freetrial",
                                 "threemonth_freetrial", "gold:monthly", "onetime_purchase"]
    }

    func testLatestExpirationDateHelper() {
        let latestExpiration = self.customerInfo.latestExpirationDate

        expect(latestExpiration).toNot(beNil())
        expect(latestExpiration) == self.customerInfo.expirationDate(forProductIdentifier: "onemonth_freetrial")
    }

    func testnonSubscriptions() throws {
        let nonConsumables = self.customerInfo.nonSubscriptions
        expect(nonConsumables).to(haveCount(1))

        let transaction = try XCTUnwrap(nonConsumables.first)
        expect(transaction.productIdentifier) == "onetime_purchase"
        expect(transaction.purchaseDate) == ISO8601DateFormatter.default.date(from: "1990-08-30T02:40:36Z")
        expect(transaction.transactionIdentifier) == "d6c007ba74"
        expect(transaction.storeTransactionIdentifier) == "340001090153249"
    }

    @available(*, deprecated) // Ignore deprecation warnings
    func testNonSubscriptionTransactions() throws {
        let nonConsumables = self.customerInfo.nonSubscriptionTransactions
        expect(nonConsumables).to(haveCount(1))

        let transaction = try XCTUnwrap(nonConsumables.first)
        expect(transaction.productIdentifier) == "onetime_purchase"
        expect(transaction.purchaseDate) == ISO8601DateFormatter.default.date(from: "1990-08-30T02:40:36Z")
        expect(transaction.transactionIdentifier) == "d6c007ba74"
    }

    @available(*, deprecated) // Ignore deprecation warnings
    func testDeprecatedParsesOtherPurchases() {
        let nonConsumables = self.customerInfo.nonConsumablePurchases

        expect(nonConsumables).to(haveCount(1))
        expect(nonConsumables).to(contain(["onetime_purchase"]))
    }

    func testOriginalApplicationVersionNilIfNotPresent() throws {
        let customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        expect(customerInfo.originalApplicationVersion).to(beNil())
    }

    func testOriginalApplicationVersionNilIfNull() throws {
        let customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": NSNull()
            ] as [String: Any]
        ])
        expect(customerInfo.originalApplicationVersion).to(beNil())
    }

    func testOriginalApplicationVersion() throws {
        let customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "original_application_version": "1.0",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        expect(customerInfo.originalApplicationVersion) == "1.0"
    }

    func testOriginalPurchaseDate() throws {
        let customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_application_version": "1.0",
                "original_app_user_id": "app_user_id",
                "original_purchase_date": "2018-10-26T23:17:53Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        expect(customerInfo.originalPurchaseDate) == Date(timeIntervalSinceReferenceDate: 562288673)
    }

    func testManagementURLNullIfNotPresent() throws {
        let customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        expect(customerInfo.managementURL).to(beNil())
    }

    func testManagementURLIsPresentWithValidURL() throws {
        let customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "management_url": "https://apple.com/manage_subscription",
                "original_app_user_id": "",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        expect(customerInfo.managementURL?.absoluteString) == "https://apple.com/manage_subscription"
    }

    func testManagementURLIsNullWithInvalidURL() throws {
        var customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "management_url": "",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_app_user_id": ""
            ] as [String: Any]
        ])
        expect(customerInfo.managementURL).to(beNil())

        customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "management_url": true,
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_app_user_id": ""
            ] as [String: Any]
        ])
        expect(customerInfo.managementURL).to(beNil())

        customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "management_url": nil,
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_app_user_id": ""
            ] as [String: Any?]
        ])
        expect(customerInfo.managementURL).to(beNil())

        customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "management_url": 3, // Invalid URL
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_app_user_id": ""
            ] as [String: Any]
        ])
        expect(customerInfo.managementURL).to(beNil())

        customerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "management_url": 68546984,
                "original_app_user_id": "",
                "first_seen": "2019-07-17T00:05:54Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        expect(customerInfo.managementURL).to(beNil())

    }

    func testDecodesRawData() throws {
        expect(self.customerInfo.rawData).toNot(beEmpty())
    }

    func testPreservesOriginalJSONSerializableObject() throws {
        expect(try CustomerInfo(data: self.customerInfo.rawData)) == self.customerInfo
    }

    func testTwoProductJson() throws {
        let jsonData = try XCTUnwrap(Self.validTwoProductsJSON.data(using: String.Encoding.utf8))
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        let jsonDict = try XCTUnwrap(jsonObject as? [String: Any])
        let info = try CustomerInfo(data: jsonDict)

        expect(info.latestExpirationDate).toNot(beNil())
    }

    func testActiveEntitlementInfos() {
        let entitlements = self.customerInfo.entitlements.active
        expect(entitlements.keys).to(contain("pro"))
        expect(entitlements.keys).toNot(contain("old_pro"))
    }

    func testRandomEntitlementInfos() {
        let entitlements = self.customerInfo.entitlements.all
        expect(entitlements.keys).toNot(contain("random"))
    }

    func testGetExpirationDates() throws {
        let proDate = try XCTUnwrap(self.customerInfo.expirationDate(forEntitlement: "pro"))
        expect(proDate.timeIntervalSince1970) == 4123276836
    }

    func testLifetimeSubscriptionsEntitlementInfos() {
        let entitlements = self.customerInfo.entitlements.active
        expect(entitlements.keys).to(contain("forever_pro"))
    }

    func testExpirationLifetime() {
        expect(self.customerInfo.expirationDate(forEntitlement: "forever_pro")).to(beNil())
    }

    func testRequestDate() {
        expect(self.customerInfo.requestDate).toNot(beNil())
    }

    func testIfRequestDateIsNilUsesCurrentTime() throws {
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
                        ] as [String: Any]
                    ],
                    "pro.3": [
                        [
                            "id": "d6c007ba75",
                            "original_purchase_date": "1990-08-30T02:40:36Z",
                            "purchase_date": "1990-08-30T02:40:36Z",
                            "is_sandbox": true,
                            "store": "play_store"
                        ] as [String: Any]
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
                        "expires_date": "2100-08-30T02:40:36Z",
                        "period_type": "normal"
                    ],
                    "pro.2": [
                        "expires_date": "1990-08-30T02:40:36Z",
                        "period_type": "normal"
                    ]
                ],
                "entitlements": [
                    "pro": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "product_identifier": "pro.1",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ],
                    "old_pro": [
                        "expires_date": "1990-08-30T02:40:36Z",
                        "product_identifier": "pro.2",
                        "purchase_date": "1990-06-30T02:40:36Z"
                    ],
                    "forever_pro": [
                        "expires_date": nil,
                        "product_identifier": "pro.3",
                        "purchase_date": "1990-08-30T02:40:36Z"
                    ]
                ]
            ] as [String: Any]
        ] as [String: Any]

        let customerInfoWithoutRequestData = try CustomerInfo(data: response)
        let entitlements = customerInfoWithoutRequestData.entitlements

        expect(Set(entitlements.all.keys)) == ["pro", "old_pro", "forever_pro"]
        expect(Set(entitlements.active.keys)) == ["pro", "forever_pro"]
    }

    func testPurchaseDateForEntitlement() throws {
        let purchaseDate = self.customerInfo.purchaseDate(forEntitlement: "pro")
        expect(purchaseDate) == Date(timeIntervalSinceReferenceDate: 562288673)
    }

    func testPurchaseDateForProductIdentifier() throws {
        let purchaseDate = try XCTUnwrap(self.customerInfo.purchaseDate(forProductIdentifier: "threemonth_freetrial"))
        expect(purchaseDate) == Date(timeIntervalSince1970: 1526797490)
    }

    func testPurchaseDateForGooglePlayProductIdentifier() throws {
        let purchaseDate = try XCTUnwrap(self.customerInfo.purchaseDate(forProductIdentifier: "gold:monthly"))
        expect(purchaseDate) == Date(timeIntervalSince1970: 1526797490)
    }

    func testPurchaseDateEmpty() throws {
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
                    "pro": [
                        "product_identifier": "onemonth_freetrial",
                        "expires_date": "2100-08-30T02:40:36Z"
                    ],
                    "old_pro": [
                        "product_identifier": "onemonth_freetrial",
                        "expires_date": "1990-08-30T02:40:36Z"
                    ],
                    "forever_pro": [
                        "product_identifier": "threemonth_freetrial",
                        "expires_date": nil
                    ]
                ] as [String: Any]
            ] as [String: Any]
        ] as [String: Any]
        let customerInfoWithoutRequestData = try CustomerInfo(data: response)
        let purchaseDate = customerInfoWithoutRequestData.purchaseDate(forEntitlement: "pro")
        expect(purchaseDate).to(beNil())
    }

    func testEmptyInfosEqual() throws {
        let info1 = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        let info2 = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        expect(info1) == info2
    }

    func testDifferentFetchDatesStillEqual() throws {
        let info1 = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        let info2 = try CustomerInfo(data: [
            "request_date": "2018-11-19T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ])
        expect(info1) == info2
    }

    func testDifferentActiveEntitlementsNotEqual() throws {
        let info1 = try CustomerInfo(data: [
            "request_date": "2018-12-20T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [
                    "pro.1": [
                        "expires_date": "2018-12-19T02:40:36Z"
                    ]],
                "other_purchases": [:] as [String: Any],
                "entitlements": [
                    "pro": [
                        "expires_date": "2018-12-19T02:40:36Z",
                        "product_identifier": "pro.1"
                    ]
                ]
            ] as [String: Any]
        ])
        let info2 = try CustomerInfo(data: [
            "request_date": "2018-11-19T02:40:36Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [
                    "pro.1": [
                        "expires_date": "2018-12-19T02:40:36Z"
                    ]
                ],
                "other_purchases": [:] as [String: Any],
                "entitlements": [
                    "pro": [
                        "expires_date": "2018-12-29T02:40:36Z",
                        "product_identifier": "pro.1"
                    ]
                ]
            ] as [String: Any]
        ])
        expect(info1) != info2
    }

    func testDifferentEntitlementsNotEqual() throws {
        let info1 = try CustomerInfo(data: [
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
                    ] as [String: Any?]
                ],
                "non_subscriptions": [:] as [String: Any],
                "entitlements": [
                    "pro": [
                        "product_identifier": "monthly_freetrial",
                        "expires_date": "2018-12-19T02:40:36Z",
                        "purchase_date": "2018-07-26T23:30:41Z"
                    ]
                ]
            ] as [String: Any]
        ])
        let info2 = try CustomerInfo(data: [
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
                    ] as [String: Any?]
                ],
                "non_subscriptions": [:] as [String: Any],
                "entitlements": [
                    "pro": [
                        "product_identifier": "monthly_freetrial",
                        "expires_date": "2018-12-19T02:40:36Z",
                        "purchase_date": "2018-07-26T23:30:41Z"
                    ]
                ]
            ] as [String: Any]
        ])
        expect(info1) != info2
    }

    func testSameEntitlementsDifferentRequestDateEqual() throws {
        let info1 = try CustomerInfo(data: [
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
                    ] as [String: Any?]
                ],
                "non_subscriptions": [:] as [String: Any],
                "entitlements": [
                    "pro": [
                        "product_identifier": "monthly_freetrial",
                        "expires_date": "2018-12-19T02:40:36Z",
                        "purchase_date": "2018-07-26T23:30:41Z"
                    ]
                ]
            ] as [String: Any]
        ])
        let info2 = try CustomerInfo(data: [
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
                    ] as [String: Any?]
                ],
                "non_subscriptions": [:] as [String: Any],
                "entitlements": [
                    "pro": [
                        "product_identifier": "monthly_freetrial",
                        "expires_date": "2018-12-19T02:40:36Z",
                        "purchase_date": "2018-07-26T23:30:41Z"
                    ]
                ]
            ] as [String: Any]
        ])
        expect(info1) == info2
    }

    func testInitFailsIfNoRequestDate() {
        expect(
            try CustomerInfo(data: [
                "subscriber": [
                    "first_seen": "2019-07-17T00:05:54Z",
                    "management_url": "https://apple.com/manage_subscription",
                    "original_app_user_id": "",
                    "subscriptions": [:] as [String: Any],
                    "other_purchases": [:] as [String: Any]
                ] as [String: Any]
            ])
        ).to(throwError())
    }

    func testInitFailsIfNoSubscriberOriginalAppUserId() {
        expect(
            try CustomerInfo(data: [
                "request_date": "2019-08-16T10:30:42Z",
                "subscriber": [
                    "first_seen": "2019-07-17T00:05:54Z",
                    "management_url": "https://apple.com/manage_subscription",
                    "subscriptions": [:] as [String: Any],
                    "other_purchases": [:] as [String: Any]
                ] as [String: Any]
            ])
        ).to(throwError())
    }

    func testInitFailsIfNoSubscriber() {
        expect(
            try CustomerInfo(data: [
                "request_date": "2019-08-16T10:30:42Z"
            ])
        ).to(throwError())
    }

    func testInitFailsIfNoSubscriberFirstSeen() {
        expect(
            try CustomerInfo(data: [
                "request_date": "2019-08-16T10:30:42Z",
                "subscriber": [
                    "management_url": "https://apple.com/manage_subscription",
                    "original_app_user_id": "",
                    "subscriptions": [:] as [String: Any],
                    "other_purchases": [:] as [String: Any]
                ] as [String: Any]
            ])
        ).to(throwError())
    }

    func testInitFailsIfMalformedRequestDate() throws {
        expect(
            try CustomerInfo(data: [
                "request_date": "2019-08-110:30:42Z",
                "subscriber": [
                    "original_app_user_id": "app_user_id",
                    "first_seen": "2019-07-17T00:05:54Z",
                    "subscriptions": [:] as [String: Any],
                    "other_purchases": [:] as [String: Any]
                ] as [String: Any]
            ])
        ).to(throwError())
    }

    func testInitFailsIfMalformedFirstSeenDate() {
        expect(
            try CustomerInfo(data: [
                "request_date": "2019-08-16T10:30:42Z",
                "subscriber": [
                    "original_app_user_id": "app_user_id",
                    "first_seen": "2019-07-",
                    "subscriptions": [:] as [String: Any],
                    "other_purchases": [:] as [String: Any]
                ] as [String: Any]
            ])
        ).to(throwError())
    }

    func testActiveSubscriptionsIncludesSubsWithNullExpirationDate() throws {
        let response = [
            "request_date": "2018-10-19T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [:] as [String: Any],
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
                    "pro": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "product_identifier": "onemonth_freetrial",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ],
                    "old_pro": [
                        "expires_date": "1990-08-30T02:40:36Z",
                        "product_identifier": "threemonth_freetrial",
                        "purchase_date": "1990-06-30T02:40:36Z"
                    ],
                    "forever_pro": [
                        "expires_date": nil,
                        "product_identifier": "onetime_purchase",
                        "purchase_date": "1990-08-30T02:40:36Z"
                    ]
                ]
            ] as [String: Any]
        ] as [String: Any]

        let info = try CustomerInfo(data: response)
        expect(info.activeSubscriptions) == Set(["onemonth_freetrial", "twomonth_freetrial"])
    }

    func testAllPurchasedProductIdentifiersIncludesNullExpDate() throws {
        let response = [
            "request_date": "2018-10-19T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [:] as [String: Any],
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
                    "pro": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "product_identifier": "onemonth_freetrial",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ],
                    "old_pro": [
                        "expires_date": "1990-08-30T02:40:36Z",
                        "product_identifier": "threemonth_freetrial",
                        "purchase_date": "1990-06-30T02:40:36Z"
                    ],
                    "forever_pro": [
                        "expires_date": nil,
                        "product_identifier": "onetime_purchase",
                        "purchase_date": "1990-08-30T02:40:36Z"
                    ]
                ]
            ] as [String: Any]
        ] as [String: Any]

        let info = try CustomerInfo(data: response)
        expect(info.allPurchasedProductIdentifiers)
        == Set(["onemonth_freetrial", "twomonth_freetrial", "threemonth_freetrial"])
    }

    func testCopyWithSameVerificationResult() throws {
        expect(self.customerInfo.copy(with: .notRequested)) === self.customerInfo
    }

    func testCopyWithVerificationResultVerified() throws {
        self.verifyCopy(of: self.customerInfo,
                        onlyModifiesEntitlementVerification: .verified)
    }

    func testCopyWithVerificationResultFailedVerified() throws {
        self.verifyCopy(of: self.customerInfo,
                        onlyModifiesEntitlementVerification: .failed)
    }

    func testCopyWithVerificationResultNotRequested() throws {
        self.verifyCopy(of: self.customerInfo.copy(with: .verified),
                        onlyModifiesEntitlementVerification: .notRequested)
    }

    func testCopyWithNewRequestDateModifiesOnlyRequestDate() throws {
        self.verifyCopy(of: self.customerInfo,
                        onlyModifiesRequestDate: Date().addingTimeInterval(-1000000))
    }

    func testCopyWithNewRequestDateUpdatesEntitlements() throws {
        expect(self.customerInfo.activeSubscriptions).toNot(contain("onemonth"))
        expect(self.customerInfo.entitlements.active).to(haveCount(3))
        expect(self.customerInfo.entitlements["expired_pro"]?.isActive) == false

        let newRequestTime = try Self.date(withDaysAgo: -2)
        let updatedCustomerInfo: CustomerInfo = self.customerInfo.copy(with: newRequestTime)
        expect(updatedCustomerInfo.activeSubscriptions).to(contain("onemonth"))
        expect(updatedCustomerInfo.entitlements.active).to(haveCount(4))
        expect(updatedCustomerInfo.entitlements["expired_pro"]?.isActive) == true
    }

    func testIsNeverComputedOfflinePriorToIOS13() throws {
        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
            throw XCTSkip("Test only for iOS 12.")
        }

        expect(self.customerInfo.copy(with: .verifiedOnDevice).isComputedOffline) == false
    }

    func testIsNotComputedOfflineIfVerificationNotRequested() {
        expect(self.customerInfo.copy(with: .notRequested).isComputedOffline) == false
    }

    func testIsNotComputedOfflineIfVerified() {
        expect(self.customerInfo.copy(with: .verified).isComputedOffline) == false
    }

    func testIsNotComputedOfflineIfFailedVerification() {
        expect(self.customerInfo.copy(with: .failed).isComputedOffline) == false
    }

    func testIsComputedOffline() throws {
        // `CustomerInfo.entitlements.verification` isn't available in iOS 12,
        // but offline CustomerInfo isn't supported anyway.
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        expect(self.customerInfo.copy(with: .verifiedOnDevice).isComputedOffline) == true
    }

    // MARK: - Private

    private func verifyCopy(
        of customerInfo: CustomerInfo,
        onlyModifiesEntitlementVerification newVerification: VerificationResult
    ) {
        let copy = customerInfo.copy(with: newVerification)
        expect(customerInfo) != copy

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            expect(copy.entitlements.verification) == newVerification

            let copyWithOriginalVerification = copy.copy(with: customerInfo.entitlements.verification)
            expect(copyWithOriginalVerification) == customerInfo
        }
    }

    private func verifyCopy(
        of customerInfo: CustomerInfo,
        onlyModifiesRequestDate newRequestDate: Date
    ) {
        let originalDate = customerInfo.requestDate

        let copy = customerInfo.copy(with: newRequestDate)
        expect(copy.requestDate) == newRequestDate
        expect(customerInfo.requestDate) == originalDate

        let copyWithOriginalDate = copy.copy(with: originalDate)
        expect(copyWithOriginalDate) == customerInfo
    }

}

extension CustomerInfo {

    convenience init?(testData: [String: Any]) {
        do {
            try self.init(data: testData)
        } catch {
            let errorDescription = (error as? DescribableError)?.description ?? error.localizedDescription
            Logger.error("Caught error creating testData, this is probably expected, right? \(errorDescription).")

            return nil
        }
    }

}

private extension BasicCustomerInfoTests {

    static let sampleTestDataWithEntitlements: [String: Any] = [
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
                ] as [String: Any?]
            ],
            "non_subscriptions": [:] as [String: Any],
            "entitlements": [
                "pro": [
                    "product_identifier": "monthly_freetrial",
                    "expires_date": "2018-12-19T02:40:36Z",
                    "purchase_date": "2018-07-26T23:30:41Z"
                ]
            ]
        ] as [String: Any]
    ]

}
