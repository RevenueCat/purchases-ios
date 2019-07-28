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

    let formatter = DateFormatter()
    var response: [String: Dictionary<String, Any>] = [:]

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

        verify(isActive: false)
    }

    func testSubscriptionWillRenew(){

    }

    func testSubscriptionWontRenewBillingError() {

    }

    func testSubscriptionWontRenewCancelled() {

    }

    func testSubscriptionWontRenewBillingErrorAndCancelled() {

    }

    func testSubscriptionIsSandbox() {

    }

    func testNonSubscription(){

    }

    func testParseStore() {

    }

    func testParsePeriod() {

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

        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(subscriberInfo).toNot(beNil())
        expect(subscriberInfo.entitlements).toNot(beNil())
        expect(subscriberInfo.originalAppUserId).to(equal("cesarsandbox1"))
        expect(subscriberInfo.entitlements.all.count).to(be(1))
        expect(subscriberInfo.entitlements.all.keys.contains("pro_cat")).to(beTrue())
        expect(subscriberInfo.entitlements.active.keys.contains("pro_cat")).to(beTrue())
        expect(proCat.identifier).to(equal("pro_cat"))
        expect(proCat.isActive).to(beTrue())
        expect(proCat.willRenew).to(beTrue())
        expect(proCat.periodType).to(equal(PeriodType.normal))
        expect(proCat.latestPurchaseDate).to(equal(formatter.date(from: "2019-07-26T23:45:40Z")))
        expect(proCat.originalPurchaseDate).to(equal(formatter.date(from: "2019-07-26T23:30:41Z")))
        expect(proCat.expirationDate).to(equal(formatter.date(from: "2200-07-26T23:50:40Z")))
        expect(proCat.store).to(equal(Store.appStore))
        expect(proCat.productIdentifier).to(equal("monthly_freetrial"))
        expect(proCat.isSandbox).to(beTrue())
        expect(proCat.unsubscribeDetectedAt).to(beNil())
        expect(proCat.billingIssueDetectedAt).to(beNil())
    }


    func testCreatesEntitlementWithNonSubscriptions() {
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
        verify(entitlementActiveTo: beTrue())
        verify(willRenew: beTrue())
//        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
//        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!
//
//        expect(subscriberInfo).toNot(beNil())
//        expect(subscriberInfo.entitlements).toNot(beNil())
//        expect(subscriberInfo.originalAppUserId).to(equal("cesarsandbox1"))
//        expect(subscriberInfo.entitlements.all.count).to(be(1))
//        expect(subscriberInfo.entitlements.all.keys.contains("pro_cat")).to(beTrue())
//        expect(subscriberInfo.entitlements.active.keys.contains("pro_cat")).to(beTrue())
//        expect(proCat.identifier).to(equal("pro_cat"))
//        expect(proCat.isActive).to(beTrue())
//        expect(proCat.willRenew).to(beTrue())
//        expect(proCat.periodType).to(equal(PeriodType.normal))
//        expect(proCat.latestPurchaseDate).to(equal(formatter.date(from: "2019-07-26T23:45:40Z")))
//        expect(proCat.originalPurchaseDate).to(beNil())
//        expect(proCat.expirationDate).to(beNil())
//        expect(proCat.store).to(equal(Store.appStore))
//        expect(proCat.productIdentifier).to(equal("lifetime"))
//        expect(proCat.isSandbox).to(beTrue())
//        expect(proCat.unsubscribeDetectedAt).to(beNil())
//        expect(proCat.billingIssueDetectedAt).to(beNil())

    }

    func verifySubscriberInfo() {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

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

    func verifyPeriodType(_ matcher: Predicate<PeriodType> = equal(PeriodType.normal)) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.periodType).to(matcher)
    }

    func verifyStore(_ matcher: Predicate<Store> = equal(Store.appStore)) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.store).to(matcher)
    }

    func verifySandbox(_ matcher: Predicate<Bool> = beFalse()) {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.isSandbox).to(matcher)
    }

    func verifyProduct() {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements["pro_cat"]!

        expect(proCat.latestPurchaseDate).to(equal(formatter.date(from: "1999-07-26T23:30:41Z")))
        expect(proCat.originalPurchaseDate).to(equal(formatter.date(from: "1999-07-26T23:30:41Z")))
        expect(proCat.expirationDate).to(equal(formatter.date(from: "2000-07-26T23:50:40Z")))
        expect(proCat.productIdentifier).to(equal("monthly_freetrial"))
    }

}
