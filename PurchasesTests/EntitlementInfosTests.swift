//
//  EntitlementInfosTests.swift
//  PurchasesTests
//
//  Created by César de la Vega  on 7/27/19.
//  Copyright © 2019 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Purchases

class EntitlementInfosTests: XCTestCase {

    private let formatter = DateFormatter()
    private var response: [String: Dictionary<String, Any>] = [:]

    override func setUp() {
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        stubResponse()
    }

    func stubResponse(entitlements: [String: Any] = [:],
                      nonSubscriptions: [String: Any] = [:],
                      subscriptions: [String: Any] = [:]) {
        response = [
            "subscriber": [
                "entitlements": entitlements,
                "first_seen": "2019-07-26T23:29:50Z",
                "non_subscriptions": nonSubscriptions,
                "original_app_user_id": "cesarsandbox1",
                "original_application_version": "1.0",
                "subscriptions": subscriptions
            ]
        ]
    }

    func testActiveSubscription(){
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "1999-07-26T23:30:41Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2000-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "1999-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "1999-07-26T23:30:41Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ]
        )

        verifyEntitlementActive()
    }

    func testInactiveSubscription() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2000-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "1999-07-26T23:30:41Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2000-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "1999-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "1999-07-26T23:30:41Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ]
        )

        verifyEntitlementActive(beFalse())
    }

    func testGetsEmptySubscriberInfo() {
        let subscriberInfo = PurchaserInfo(data: response)

        expect(subscriberInfo?.firstSeen).toNot(beNil())
        expect(subscriberInfo?.originalAppUserId).to(equal("cesarsandbox1"))
        expect(subscriberInfo?.entitlements.all.count).to(be(0))
    }

    func testCreatesEntitlementInfos() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }


    func testCreatesEntitlementWithNonSubscriptionsAndSubscription() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "app_store"
                        ],
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ]
        )

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct(identifier: equal("lifetime"), latestPurchaseDate: equal(formatter.date(from: "2019-07-26T23:45:40Z")), originalPurchaseDate: beNil(), expirationDate: beNil())
    }


    func testSubscriptionWillRenew(){
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }

    func testSubscriptionWontRenewBillingError() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": "2019-07-27T23:30:41Z",
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal(beFalse(), billingIssueDetectedAt: equal(formatter.date(from: "2019-07-27T23:30:41Z")))
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }

    func testSubscriptionWontRenewCancelled() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": "2019-07-27T23:30:41Z"
                    ]
                ])

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal(beFalse(), unsubscribeDetectedAt: equal(formatter.date(from: "2019-07-27T23:30:41Z")))
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }

    func testSubscriptionWontRenewBillingErrorAndCancelled() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": "2019-07-27T22:30:41Z",
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": "2019-07-27T23:30:41Z"
                    ]
                ])

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal(beFalse(), unsubscribeDetectedAt: equal(formatter.date(from: "2019-07-27T23:30:41Z")), billingIssueDetectedAt: equal(formatter.date(from: "2019-07-27T22:30:41Z")))
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }

    func testSubscriptionIsSandbox() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": true,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox(beTrue())
        verifyProduct()
    }

    func testNonSubscription(){
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "app_store"
                        ],
                    ]
                ],
                subscriptions: [:]
        )

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct(identifier: equal("lifetime"), latestPurchaseDate: equal(formatter.date(from: "2019-07-26T23:45:40Z")), originalPurchaseDate: beNil(), expirationDate: beNil())

    }

    func testParseStoreFromSubscription() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        verifyStore(equal(Store.appStore.rawValue))
        
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "mac_app_store",
                    "unsubscribe_detected_at": nil
                ]
            ])
        verifyStore(equal(Store.macAppStore.rawValue))
        
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "play_store",
                    "unsubscribe_detected_at": nil
                ]
            ])
        verifyStore(equal(Store.playStore.rawValue))
        
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "promotional",
                    "unsubscribe_detected_at": nil
                ]
            ])
        verifyStore(equal(Store.promotional.rawValue))
        
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "stripe",
                    "unsubscribe_detected_at": nil
                ]
            ])
        verifyStore(equal(Store.stripe.rawValue))
        
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "tienda",
                    "unsubscribe_detected_at": nil
                ]
            ])
        verifyStore(equal(Store.unknownStore.rawValue))
    }

    func testParseStoreFromNonSubscription() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "app_store"
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(equal(Store.appStore.rawValue))

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "mac_app_store"
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(equal(Store.macAppStore.rawValue))

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "play_store"
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(equal(Store.playStore.rawValue))

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "promotional"
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(equal(Store.promotional.rawValue))

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "stripe"
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(equal(Store.stripe.rawValue))

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "tienda"
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(equal(Store.unknownStore.rawValue))
    }

    func testParsePeriod() {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        verifyPeriodType(equal(PeriodType.normal.rawValue))

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "intro",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])
        verifyPeriodType(equal(PeriodType.intro.rawValue))

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "trial",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])
        verifyPeriodType(equal(PeriodType.trial.rawValue))

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "period",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])
        verifyPeriodType(equal(PeriodType.normal.rawValue))
    }

    func testParsePeriodForNonSubscription() {
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": nil,
                    "product_identifier": "lifetime",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            nonSubscriptions: [
                "lifetime": [
                    [
                        "id": "5b9ba226bc",
                        "is_sandbox": false,
                        "purchase_date": "2019-07-26T22:10:27Z",
                        "store": "app_store"
                    ],
                    [
                        "id": "ea820afcc4",
                        "is_sandbox": false,
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store"
                    ],
                ]
            ],
            subscriptions: [:]
        )
        verifyPeriodType(equal(PeriodType.normal.rawValue))
    }

    func verifySubscriberInfo() {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!

        expect(subscriberInfo).toNot(beNil())
        expect(subscriberInfo.firstSeen).to(equal(formatter.date(from: "2019-07-26T23:29:50Z")))
        expect(subscriberInfo.originalAppUserId).to(equal("cesarsandbox1"))
    }

    func verifyEntitlementActive(_ matcher: Predicate<Bool> = beTrue()) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.identifier).to(equal("pro_cat"))
        expect(subscriberInfo.entitlements.all.count).to(be(1))
        expect(subscriberInfo.entitlements.all.keys.contains("pro_cat")).to(beTrue())
        expect(subscriberInfo.entitlements.active.keys.contains("pro_cat")).to(matcher)
        expect(proCat.isActive).to(matcher)
    }

    func verifyRenewal(_ matcher: Predicate<Bool> = beTrue(),
                unsubscribeDetectedAt: Predicate<Date> = beNil(),
                billingIssueDetectedAt: Predicate<Date> = beNil()) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.willRenew).to(matcher)
        expect(proCat.unsubscribeDetectedAt).to(unsubscribeDetectedAt)
        expect(proCat.billingIssueDetectedAt).to(billingIssueDetectedAt)
    }

    func verifyPeriodType(_ matcher: Predicate<Int> = equal(PeriodType.normal.rawValue)) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.periodType.rawValue).to(matcher)
    }

    func verifyStore(_ matcher: Predicate<Int> = equal(Store.appStore.rawValue)) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.store.rawValue).to(matcher)
    }

    func verifySandbox(_ matcher: Predicate<Bool> = beFalse()) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.isSandbox).to(matcher)
    }
    
    func verifyProduct(identifier: Predicate<String> = equal("monthly_freetrial")) {
        verifyProduct(identifier: identifier,
                latestPurchaseDate: equal(formatter.date(from: "2019-07-26T23:45:40Z")),
                originalPurchaseDate: equal(formatter.date(from: "2019-07-26T23:30:41Z")),
                expirationDate: equal(formatter.date(from: "2200-07-26T23:50:40Z"))
        )
    }

    func verifyProduct(identifier: Predicate<String>,
                       latestPurchaseDate: Predicate<Date>,
                       originalPurchaseDate: Predicate<Date>,
                       expirationDate: Predicate<Date>) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.latestPurchaseDate).to(latestPurchaseDate)
        expect(proCat.originalPurchaseDate).to(originalPurchaseDate)
        expect(proCat.expirationDate).to(expirationDate)
        expect(proCat.productIdentifier).to(identifier)
    }
}
