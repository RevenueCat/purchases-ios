//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHandlerTests.swift
//
//  Created by Nacho Soto on 7/31/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class PurchaseHandlerTests: TestCase {

    func testInitialState() async throws {
        let handler: PurchaseHandler = .mock()

        expect(handler.purchaseResult).to(beNil())
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.purchased) == false
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.restoreInProgress) == false
        expect(handler.actionInProgress) == false
        expect(handler.purchaseError).to(beNil())
        expect(handler.restoreError).to(beNil())
    }

    func testPurchaseSetsCustomerInfo() async throws {
        let handler: PurchaseHandler = .mock()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        expect(handler.purchaseResult?.customerInfo) === TestData.customerInfo
        expect(handler.purchaseResult?.userCancelled) == false
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.purchased) == true
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.restoreInProgress) == false
        expect(handler.actionInProgress) == false
    }

    func testCancellingPurchase() async throws {
        let handler: PurchaseHandler = .cancelling()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)
        expect(handler.purchaseResult?.userCancelled) == true
        expect(handler.purchaseResult?.customerInfo) === TestData.customerInfo
        expect(handler.purchased) == false
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.restoreInProgress) == false
        expect(handler.actionInProgress) == false
    }

    func testFailingPurchase() async throws {
        let error: ErrorCode = .storeProblemError

        let handler: PurchaseHandler = .failing(error)

        do {
            _ = try await handler.purchase(package: TestData.packageWithIntroOffer)
            fail("Expected error")
        } catch let thrownError {
            expect(thrownError).to(matchError(error))
        }

        expect(handler.purchaseResult).to(beNil())
        expect(handler.purchased) == false
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.restoreInProgress) == false
        expect(handler.actionInProgress) == false
        expect(handler.purchaseError).to(matchError(error))
        expect(handler.restoreError).to(beNil())
    }

    func testInProgressPropertiesDuringPurchase() async throws {
        self.continueAfterFailure = false

        let asyncHandler = AsyncPurchaseHandler()
        let handler = asyncHandler.purchaseHandler!

        let task = Task.detached {
            _ = try await handler.purchase(package: TestData.packageWithIntroOffer)
        }

        try await asyncWait {
            handler.actionInProgress && handler.packageBeingPurchased != nil
        }

        expect(handler.packageBeingPurchased) == TestData.packageWithIntroOffer
        expect(handler.actionInProgress) == true
        expect(handler.restoreInProgress) == false

        // Finish purchase
        try asyncHandler.resume()

        // Wait for purchase task to complete
        _ = try await task.value

        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.actionInProgress) == false
    }

    func testInProgressPropertiesDuringRestore() async throws {
        self.continueAfterFailure = false

        let asyncHandler = AsyncPurchaseHandler()
        let handler = asyncHandler.purchaseHandler!

        let task = Task.detached {
            _ = try await handler.restorePurchases()
        }

        try await asyncWait {
            handler.actionInProgress
        }

        expect(handler.actionInProgress) == true
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.restoreInProgress) == true

        // Finish restore
        try asyncHandler.resume()

        // Wait for restore task to complete
        _ = try await task.value

        expect(handler.actionInProgress) == false
    }

    func testRestorePurchases() async throws {
        let handler: PurchaseHandler = .mock()
        let result = try await handler.restorePurchases()

        expect(result.info) === TestData.customerInfo
        expect(result.success) == false
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.purchaseResult).to(beNil())
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.actionInProgress) == false
        expect(handler.restoreInProgress) == false

        handler.setRestored(TestData.customerInfo)

        expect(handler.restoredCustomerInfo) === TestData.customerInfo
        expect(handler.purchaseResult).to(beNil())
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.actionInProgress) == false
        expect(handler.restoreInProgress) == false
    }

    func testRestorePurchasesWithActiveSubscriptions() async throws {
        let handler: PurchaseHandler = .mock(Self.customerInfoWithSubscriptions)

        let result = try await handler.restorePurchases()
        expect(result.info) === Self.customerInfoWithSubscriptions
        expect(result.success) == true
    }

    func testRestorePurchasesWithNonSubscriptions() async throws {
        let handler: PurchaseHandler = .mock(Self.customerInfoWithNonSubscriptions)

        let result = try await handler.restorePurchases()
        expect(result.info) === Self.customerInfoWithNonSubscriptions
        expect(result.success) == true
    }

    func testFailingRestore() async throws {
        let error: ErrorCode = .storeProblemError
        let handler: PurchaseHandler = .failing(error)

        do {
            _ = try await handler.restorePurchases()
            fail("Expected error")
        } catch let thrownError {
            expect(thrownError).to(matchError(error))
        }
        expect(handler.purchaseResult).to(beNil())
        expect(handler.purchased) == false
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.actionInProgress) == false
        expect(handler.restoreInProgress) == false
        expect(handler.restoreError).to(matchError(error))
        expect(handler.purchaseError).to(beNil())
    }

    func testCloseEventIsTrackedOnlyAfterImpressionAndOnlyOnce() async throws {
        let handler: PurchaseHandler = .mock()

        let eventData: PaywallEvent.Data = .init(
            offering: TestData.offeringWithIntroOffer,
            paywall: TestData.paywallWithIntroOffer,
            sessionID: .init(),
            displayMode: .fullScreen,
            locale: .init(identifier: "en_US"),
            darkMode: false
        )

        let result1 = handler.trackPaywallClose()
        expect(result1) == false

        handler.trackPaywallImpression(eventData)

        let result2 = handler.trackPaywallClose()
        expect(result2) == true
        let result3 = handler.trackPaywallClose()
        expect(result3) == false

    }
}

// MARK: - Private

/// `PurchaseHandler` decorator that allows controlling when purchases / restores finish.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class AsyncPurchaseHandler {

    // Note: We're using UnsafeContinuation instead of Checked because
    // of a crash in iOS 18.0 devices when CheckedContinuations are used.
    // See: https://github.com/RevenueCat/purchases-ios/issues/4177
    var continuation: UnsafeContinuation<Void, Never>?
    private(set) var purchaseHandler: PurchaseHandler!

    init() {
        self.purchaseHandler = .init(
            purchases: MockPurchases { [weak instance = self] _ in
                let instance = try XCTUnwrap(instance)

                await instance.createAndWaitForContinuation()

                return (
                    transaction: nil,
                    customerInfo: TestData.customerInfo,
                    userCancelled: false
                )
            } restorePurchases: { [weak instance = self] in
                let instance = try XCTUnwrap(instance)
                await instance.createAndWaitForContinuation()

                return TestData.customerInfo
            } trackEvent: { event in
                Logger.debug("Tracking event: \(event)")
            } customerInfo: { [weak instance = self] in
                let instance = try XCTUnwrap(instance)
                await instance.createAndWaitForContinuation()

                return TestData.customerInfo
            }
        )
    }

    func resume() throws {
        try XCTUnwrap(self.continuation).resume(returning: ())
     }

    private func createAndWaitForContinuation() async {
        await withUnsafeContinuation { [weak self] continuation in
            self?.continuation = continuation
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PurchaseHandlerTests {

    static let customerInfoWithSubscriptions: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                    "com.revenuecat.product": {
                        "billing_issues_detected_at": null,
                        "expires_date": "2062-04-12T00:03:35Z",
                        "grace_period_expires_date": null,
                        "is_sandbox": true,
                        "original_purchase_date": "2022-04-12T00:03:28Z",
                        "period_type": "intro",
                        "purchase_date": "2022-04-12T00:03:28Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": null
                    },
                },
                "entitlements": {
                }
            }
        }
        """
        )
    }()

    static let customerInfoWithNonSubscriptions: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                    "com.revenuecat.product.tip": [
                        {
                            "purchase_date": "2022-02-11T00:03:28Z",
                            "original_purchase_date": "2022-03-10T00:04:28Z",
                            "id": "17459f5ff7",
                            "store_transaction_id": "340001090153249",
                            "store": "app_store",
                            "is_sandbox": false
                        }
                    ]
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                },
                "entitlements": {
                }
            }
        }
        """
        )
    }()

}

#endif
