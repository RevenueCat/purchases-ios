//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutTests.swift
//
//  Created by Antonio Pallares on 11/9/26.

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS) && canImport(WebKit)

@available(iOS 15.0, *)
final class HostedCheckoutTests: TestCase {

    private static let session = HostedCheckoutSession(
        operationSessionID: "oper_1",
        checkoutURL: URL(string: "https://checkout.stripe.com/c/pay/session_1")!,
        successURL: URL(string: "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=success")!,
        cancelURL: URL(string: "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=cancel")!
    )

    /// The checkout is asked for through the handler, which is the paywall's only way to the SDK.
    func testAsksTheHandlerForTheCheckout() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _ in .started(Self.session) }

        let start = await HostedCheckout.start(for: TestData.annualPackage,
                                               purchaseHandler: Self.makeHandler(purchases: purchases))

        expect(start) == .present(Self.session)
    }

    func testPresentsTheCheckoutThatWasCreated() {
        expect(HostedCheckout.Start(.started(Self.session))) == .present(Self.session)
    }

    /// There is no checkout to open for something the customer already has, and they are told so rather than
    /// left with a button that appears to do nothing.
    func testTellsTheCustomerWhenTheyAlreadyOwnTheProduct() {
        expect(HostedCheckout.Start(.alreadyPurchased)) == .tellCustomerTheyAlreadyOwnIt
    }

    /// A customer who said no to Apple's notice said no to the purchase.
    func testOffersNothingWhenTheCustomerDeclinedTheNotice() {
        expect(HostedCheckout.Start(.declinedByCustomer)) == .nothing
    }

    /// Apple asks that a device that does not authorize payments be offered no purchase at all, not even
    /// through StoreKit.
    func testOffersNothingWhenTheDeviceDoesNotAuthorizePayments() {
        expect(HostedCheckout.Start(.paymentsNotAuthorized)) == .nothing
    }

    /// Where the customer's storefront does not allow the purchase outside the App Store, there is nothing to
    /// offer them in its place.
    func testOffersNothingWhereTheStorefrontDoesNotAllowThePurchase() {
        expect(HostedCheckout.Start(.notAllowedInStorefront)) == .nothing
    }

    /// The checkout already under way carries the purchase.
    func testOffersNothingWhileAnotherCheckoutIsStarting() {
        expect(HostedCheckout.Start(.alreadyStarting)) == .nothing
    }

    /// Falling back to StoreKit here would charge a customer who is midway through a checkout that may yet
    /// be resolved, so a failure offers nothing.
    func testOffersNothingWhenTheCheckoutCouldNotBeCreated() {
        expect(HostedCheckout.Start(.failed)) == .nothing
    }

}

@available(iOS 15.0, *)
private extension HostedCheckoutTests {

    static func makePurchases() -> MockPurchases {
        return MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            return TestData.customerInfo
        }
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
