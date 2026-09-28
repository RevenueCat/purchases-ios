//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseLinkTests.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ExternalPurchaseLinkTests: TestCase {

    func testAppendsTheTokenIDToALinkWithNoQuery() throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))

        expect(url.appendingExternalPurchaseTokenID("token_id").absoluteString)
            == "https://pay.rev.cat/abc/user_1?rc_external_purchase_token_id=token_id"
    }

    func testKeepsTheExistingQueryAndFragment() throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1?rc_source=paywall#step"))

        expect(url.appendingExternalPurchaseTokenID("token_id").absoluteString)
            == "https://pay.rev.cat/abc/user_1?rc_source=paywall&rc_external_purchase_token_id=token_id#step"
    }

    func testReplacesATokenIDThatIsAlreadyThere() throws {
        let url = try XCTUnwrap(
            URL(string: "https://pay.rev.cat/abc/user_1?rc_external_purchase_token_id=stale")
        )

        expect(url.appendingExternalPurchaseTokenID("token_id").absoluteString)
            == "https://pay.rev.cat/abc/user_1?rc_external_purchase_token_id=token_id"
    }

    func testOpensTheLinkWithTheTokenID() throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))

        expect(ExternalPurchaseLink.Action(.proceed(externalPurchaseTokenID: "token_id"), url: url))
            == .open(url.appendingExternalPurchaseTokenID("token_id"))
    }

    func testOpensTheLinkAsItIsWithoutATokenID() throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))

        expect(ExternalPurchaseLink.Action(.proceed(externalPurchaseTokenID: nil), url: url)) == .open(url)
    }

    /// A customer who is not eligible to buy outside the App Store is told the purchase is unavailable rather
    /// than left with a button that appears to do nothing.
    func testTellsAnIneligibleCustomerThePurchaseIsUnavailable() throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))

        expect(ExternalPurchaseLink.Action(.notEligible, url: url)) == .tellCustomerThePurchaseIsUnavailable
    }

    func testOpensNothingWhenThePreparationStopped() throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))

        expect(ExternalPurchaseLink.Action(.stopped, url: url)) == .nothing
    }

    /// The link is prepared through the handler, which is the paywall's only way to the SDK.
    func testAsksTheHandlerToPrepareAnExternalBrowserLink() async throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))
        let purchases = Self.makePurchases(usingExternalPurchaseCustomLinks: true)
        purchases.externalPurchaseLinkBlock = { .notEligible }

        let action = await ExternalPurchaseLink.action(for: url,
                                                       method: .externalBrowser,
                                                       purchaseHandler: Self.makeHandler(purchases: purchases))

        expect(action) == .tellCustomerThePurchaseIsUnavailable
    }

    /// Only leaving the app is covered by Apple's programme.
    func testOpensALinkThatStaysInTheAppWithoutPreparingIt() async throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))
        let purchases = Self.makePurchases(usingExternalPurchaseCustomLinks: true)
        purchases.externalPurchaseLinkBlock = { .notEligible }

        let action = await ExternalPurchaseLink.action(for: url,
                                                       method: .inAppBrowser,
                                                       purchaseHandler: Self.makeHandler(purchases: purchases))

        expect(action) == .open(url)
    }

    func testOpensTheLinkWithoutPreparingItWhileCustomLinksAreDisabled() async throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))
        let purchases = Self.makePurchases(usingExternalPurchaseCustomLinks: false)
        purchases.externalPurchaseLinkBlock = { .notEligible }

        let action = await ExternalPurchaseLink.action(for: url,
                                                       method: .externalBrowser,
                                                       purchaseHandler: Self.makeHandler(purchases: purchases))

        expect(action) == .open(url)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ExternalPurchaseLinkTests {

    static func makePurchases(usingExternalPurchaseCustomLinks: Bool) -> MockPurchases {
        let purchases = MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            return TestData.customerInfo
        }
        purchases.useExternalPurchaseCustomLinks = usingExternalPurchaseCustomLinks
        return purchases
    }

    static func makeHandler(purchases: MockPurchases) -> PurchaseHandler {
        return PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(purchases: purchases,
                                eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )
    }

}

#endif
