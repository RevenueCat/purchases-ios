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

import Combine
import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class PurchaseHandlerTests: TestCase {

    private static let urlOpenedURL = URL(string: "https://revenuecat.com/terms")!

    private var purchaseResult = CurrentValueSubject<PurchaseResultData, Never>((nil, TestData.customerInfo, false))

    lazy var purchaseResultPublisher = purchaseResult.dropFirst().eraseToAnyPublisher()

    func testInitialState() async throws {
        let handler: PurchaseHandler = .mock()

        expect(handler.purchaseResult).to(beNil())
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.hasPurchasedInSession) == false
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.restoreInProgress) == false
        expect(handler.actionInProgress) == false
        expect(handler.purchaseError).to(beNil())
        expect(handler.restoreError).to(beNil())
    }

    func testCustomPurchaseSuccessClearsLoadingState() async throws {
        try await self.checkCustomPurchaseLoadingState(userCancelled: false, error: nil)
    }

    func testCustomPurchaseCancellationClearsLoadingState() async throws {
        try await self.checkCustomPurchaseLoadingState(userCancelled: true, error: nil)
    }

    func testCustomPurchaseFailureClearsLoadingState() async throws {
        try await self.checkCustomPurchaseLoadingState(userCancelled: false, error: ErrorCode.storeProblemError)
    }

    func testCustomPurchaseCustomerInfoFailureClearsLoadingState() async throws {
        let purchases = MockPurchases(purchasesAreCompletedBy: .myApp) { _, _, _ in
            XCTFail("The app must complete its own purchase")
            return (nil, TestData.customerInfo, false)
        } restorePurchases: {
            TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            throw ErrorCode.networkError
        }
        let handler = PurchaseHandler(
            purchases: purchases,
            performPurchase: { _ in (false, nil) },
            eventTracker: .init(purchases: purchases)
        )

        do {
            try await handler.purchase(package: TestData.packageWithIntroOffer)
            XCTFail("Expected the customer info error")
        } catch {
            XCTAssertEqual(error as? ErrorCode, .networkError)
        }

        XCTAssertNil(handler.packageBeingPurchased)
        XCTAssertFalse(handler.actionInProgress)
    }

    func testCustomPurchaseCanRetryAfterCancellation() async throws {
        var packages: [Package] = []
        let handler = PurchaseHandler.mock(purchasesAreCompletedBy: .myApp, performPurchase: { package in
            packages.append(package)
            return (userCancelled: packages.count == 1, error: nil)
        })

        try await handler.purchase(package: TestData.packageWithIntroOffer)
        XCTAssertNil(handler.packageBeingPurchased)
        expect(handler.purchaseResult) == .cancelled

        try await handler.purchase(package: TestData.annualPackage)
        XCTAssertNil(handler.packageBeingPurchased)
        XCTAssertFalse(handler.actionInProgress)
        XCTAssertEqual(packages.count, 2)
        XCTAssertTrue(packages[0] === TestData.packageWithIntroOffer)
        XCTAssertTrue(packages[1] === TestData.annualPackage)
        expect(handler.purchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
    }

    private func checkCustomPurchaseLoadingState(userCancelled: Bool, error expectedError: Error?) async throws {
        weak var handlerReference: PurchaseHandler?
        let handler = PurchaseHandler.mock(purchasesAreCompletedBy: .myApp, performPurchase: { package in
            XCTAssertTrue(handlerReference?.packageBeingPurchased === package)
            XCTAssertTrue(handlerReference?.actionInProgress == true)
            return (userCancelled, expectedError)
        })
        handlerReference = handler

        do {
            try await handler.purchase(package: TestData.packageWithIntroOffer)
            XCTAssertNil(expectedError)
        } catch {
            XCTAssertNotNil(expectedError)
            XCTAssertEqual(error as? ErrorCode, expectedError as? ErrorCode)
        }

        XCTAssertNil(handler.packageBeingPurchased)
        XCTAssertFalse(handler.actionInProgress)
        XCTAssertFalse(handler.restoreInProgress)
        if expectedError != nil {
            XCTAssertNotNil(handler.purchaseError)
            XCTAssertNil(handler.purchaseResult)
        } else if userCancelled {
            expect(handler.purchaseResult) == .cancelled
        } else {
            expect(handler.purchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
        }
    }

    func testPurchaseSetsCustomerInfo() async throws {
        let handler: PurchaseHandler = .mock()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        expect(handler.purchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.hasPurchasedInSession) == true
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.restoreInProgress) == false
        expect(handler.actionInProgress) == false
    }

    func testCancellingPurchase() async throws {
        let handler: PurchaseHandler = .cancelling()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)
        expect(handler.purchaseResult) == .cancelled
        expect(handler.hasPurchasedInSession) == false
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
        expect(handler.hasPurchasedInSession) == false
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.restoreInProgress) == false
        expect(handler.actionInProgress) == false
        expect(handler.purchaseError).to(matchError(error))
        expect(handler.restoreError).to(beNil())
    }

    @MainActor
    func testResetForNewSessionClearsRestoredCustomerInfo() async throws {
        // The handler is held as a @StateObject and reused across present/dismiss cycles, so a successful
        // restore from one session must not leak into the next (it is a per-session completion signal that
        // gates workflow_close abandonment).
        let handler: PurchaseHandler = .mock()
        handler.setRestored(TestData.customerInfo, success: true)
        expect(handler.restoredCustomerInfo?.success) == true

        handler.resetForNewSession()

        expect(handler.restoredCustomerInfo).to(beNil())
    }

    @MainActor
    func testURLEventsSurviveImmediateResetAndRepeat() {
        let handler: PurchaseHandler = .mock()
        var urls: [URL] = []
        var checkoutCount = 0
        let urlSubscription = handler.urlOpenedPublisher.sink { urls.append($0) }
        let checkoutSubscription = handler.webCheckoutOpenedPublisher.sink { checkoutCount += 1 }
        defer {
            urlSubscription.cancel()
            checkoutSubscription.cancel()
        }

        handler.signalURLOpened(Self.urlOpenedURL)
        handler.signalWebCheckoutOpened()
        handler.resetForNewSession()
        handler.signalURLOpened(Self.urlOpenedURL)
        handler.signalWebCheckoutOpened()

        expect(urls) == [Self.urlOpenedURL, Self.urlOpenedURL]
        expect(checkoutCount) == 2
    }

    @MainActor
    func testURLEventsDoNotReplayToNewSubscribers() {
        let handler: PurchaseHandler = .mock()
        handler.signalURLOpened(Self.urlOpenedURL)
        handler.signalWebCheckoutOpened()

        var urls: [URL] = []
        var checkoutCount = 0
        let urlSubscription = handler.urlOpenedPublisher.sink { urls.append($0) }
        let checkoutSubscription = handler.webCheckoutOpenedPublisher.sink { checkoutCount += 1 }
        defer {
            urlSubscription.cancel()
            checkoutSubscription.cancel()
        }

        expect(urls).to(beEmpty())
        expect(checkoutCount) == 0
        handler.resetForNewSession()
        handler.signalURLOpened(Self.urlOpenedURL)
        handler.signalWebCheckoutOpened()
        expect(urls) == [Self.urlOpenedURL]
        expect(checkoutCount) == 1
    }

    func testCancelEventContainsProductIdentifierWhenCompletedByRevenueCat() async throws {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])

        let purchases = MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: true)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { event in
            trackedEvents.modify { $0.append(event) }
        } customerInfo: {
            return TestData.customerInfo
        }
        let handler = PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(purchases: purchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil
        )
        handler.trackPaywallImpression(eventData)

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        await expect(trackedEvents.value.contains(where: {
            if case .cancel = $0 { return true }
            return false
        })).toEventually(beTrue(), timeout: .seconds(2))

        let cancelEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .cancel = $0 { return true }
            return false
        }))
        expect(cancelEvent.data.productId) == TestData.packageWithIntroOffer.storeProduct.productIdentifier
    }

    func testCancelEventContainsProductIdentifierWhenCompletedByMyApp() async throws {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])

        let purchases = MockPurchases(
            purchasesAreCompletedBy: .myApp
        ) { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { event in
            trackedEvents.modify { $0.append(event) }
        } customerInfo: {
            return TestData.customerInfo
        }
        let handler = PurchaseHandler(
            purchases: purchases,
            performPurchase: { _ in (userCancelled: true, error: nil) },
            performRestore: { (success: true, error: nil) },
            eventTracker: .init(purchases: purchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil
        )
        handler.trackPaywallImpression(eventData)

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        await expect(trackedEvents.value.contains(where: {
            if case .cancel = $0 { return true }
            return false
        })).toEventually(beTrue(), timeout: .seconds(2))

        let cancelEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .cancel = $0 { return true }
            return false
        }))
        expect(cancelEvent.data.productId) == TestData.packageWithIntroOffer.storeProduct.productIdentifier
    }

    func testCustomPurchaseReceivesSelectedPromotionalOffer() async throws {
        let offer = self.promotionalOffer
        var receivedContext: PaywallPurchaseContext?
        let logic = MyAppPurchaseLogic(performPurchaseWithContext: { context in
            receivedContext = context
            return (userCancelled: false, error: nil)
        }, performRestore: { (success: true, error: nil) })
        let handler = PurchaseHandler.mock(
            purchasesAreCompletedBy: .myApp,
            performRestore: logic.performRestore,
            performPurchaseWithContext: logic.performPurchaseWithContext
        )

        try await handler.purchase(package: TestData.packageWithIntroOffer, promotionalOffer: offer)

        let context = try XCTUnwrap(receivedContext)
        XCTAssertTrue(context.package === TestData.packageWithIntroOffer)
        XCTAssertTrue(context.promotionalOffer === offer)
        expect(handler.purchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
    }

    func testCustomPurchaseWithoutOfferReceivesNil() async throws {
        var receivedContext: PaywallPurchaseContext?
        let handler = PurchaseHandler.mock(purchasesAreCompletedBy: .myApp, performPurchaseWithContext: { context in
            receivedContext = context
            return (userCancelled: false, error: nil)
        })

        try await handler.purchase(package: TestData.packageWithIntroOffer)

        let context = try XCTUnwrap(receivedContext)
        XCTAssertTrue(context.package === TestData.packageWithIntroOffer)
        XCTAssertNil(context.promotionalOffer)
    }

    func testLegacyCustomPurchaseStillReceivesPackageWhenOfferIsSelected() async throws {
        var receivedPackage: Package?
        let logic = MyAppPurchaseLogic(performPurchase: { package in
            receivedPackage = package
            return (userCancelled: false, error: nil)
        }, performRestore: { (success: true, error: nil) })
        let handler = PurchaseHandler.mock(purchasesAreCompletedBy: .myApp,
                                           performPurchase: logic.performPurchase)

        try await handler.purchase(package: TestData.packageWithIntroOffer, promotionalOffer: self.promotionalOffer)

        XCTAssertTrue(receivedPackage === TestData.packageWithIntroOffer)
        expect(handler.purchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
        _ = await logic.performPurchaseWithContext(.init(package: TestData.packageWithIntroOffer,
                                                         promotionalOffer: self.promotionalOffer))
        XCTAssertTrue(receivedPackage === TestData.packageWithIntroOffer)
    }

    func testContextPurchaseCancellation() async throws {
        let handler = PurchaseHandler.mock(purchasesAreCompletedBy: .myApp, performPurchaseWithContext: { _ in
            return (userCancelled: true, error: nil)
        })

        try await handler.purchase(package: TestData.packageWithIntroOffer, promotionalOffer: self.promotionalOffer)

        expect(handler.purchaseResult) == .cancelled
        XCTAssertFalse(handler.actionInProgress)
        XCTAssertNil(handler.purchaseError)
    }

    func testContextPurchaseError() async throws {
        let handler = PurchaseHandler.mock(purchasesAreCompletedBy: .myApp, performPurchaseWithContext: { _ in
            return (userCancelled: false, error: ErrorCode.storeProblemError)
        })

        do {
            try await handler.purchase(package: TestData.packageWithIntroOffer, promotionalOffer: self.promotionalOffer)
            XCTFail("Expected the custom purchase error")
        } catch {
            XCTAssertEqual(error as? ErrorCode, .storeProblemError)
        }

        XCTAssertNotNil(handler.purchaseError)
        XCTAssertFalse(handler.actionInProgress)
    }

    func testRevenueCatManagedPurchaseDoesNotCallCustomContextCallback() async throws {
        let handler = PurchaseHandler.mock(performPurchaseWithContext: { _ in
            XCTFail("RevenueCat-managed purchases must not invoke the custom callback")
            return (userCancelled: false, error: nil)
        })

        try await handler.purchase(package: TestData.packageWithIntroOffer, promotionalOffer: self.promotionalOffer)

        expect(handler.purchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
    }

    func testContextLogicKeepsLegacyPurchasePropertyCallable() async {
        var receivedContext: PaywallPurchaseContext?
        let logic = MyAppPurchaseLogic(performPurchaseWithContext: { context in
            receivedContext = context
            return (userCancelled: true, error: nil)
        }, performRestore: { (success: true, error: nil) })

        let result = await logic.performPurchase(TestData.packageWithIntroOffer)

        XCTAssertTrue(result.userCancelled)
        XCTAssertTrue(receivedContext?.package === TestData.packageWithIntroOffer)
        XCTAssertNil(receivedContext?.promotionalOffer)
    }

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
    func testObjectiveCContextHandlerBridgePreservesOfferAndResults() async throws {
        let delegate = ContextPurchaseHandlerSpy()
        let bridged = PaywallViewController.bridgePurchaseHandlerWithContext(delegate)
        let context = PaywallPurchaseContext(package: TestData.packageWithIntroOffer,
                                             promotionalOffer: self.promotionalOffer)

        let purchaseResult = await bridged.performPurchaseWithContext(context)
        let restoreResult = await bridged.performRestore()

        XCTAssertTrue(delegate.context === context)
        XCTAssertTrue(purchaseResult.userCancelled)
        XCTAssertEqual(purchaseResult.error as? ErrorCode, .storeProblemError)
        XCTAssertTrue(restoreResult.success)
        XCTAssertNil(restoreResult.error)
    }
    #endif

    private var promotionalOffer: PromotionalOffer {
        PromotionalOffer(
            discount: MockStoreProductDiscount(
                offerIdentifier: "promo", currencyCode: "USD", price: 1, localizedPriceString: "$1.00",
                paymentMode: .payAsYouGo, subscriptionPeriod: .init(value: 1, unit: .month),
                numberOfPeriods: 1, type: .promotional
            ),
            signedData: .init(
                identifier: "promo", keyIdentifier: "key", nonce: UUID(), signature: "signature", timestamp: 1234
            )
        )
    }

    func testCancellingAPurchaseCompletedByMyAppDoesNotNeedCustomerInfo() async throws {
        let handler = Self.handlerFailingToFetchCustomerInfo(
            purchasesAreCompletedBy: .myApp,
            performPurchase: { _ in (userCancelled: true, error: nil) }
        )

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        expect(handler.purchaseResult) == .cancelled
        expect(handler.sessionPurchaseResult) == .cancelled
        expect(handler.purchaseError).to(beNil())
    }

    func testHostedCheckoutDismissalDoesNotNeedCustomerInfo() {
        let handler = Self.handlerFailingToFetchCustomerInfo(purchasesAreCompletedBy: .revenueCat,
                                                             performPurchase: nil)

        handler.handleHostedCheckoutDismissal(package: TestData.packageWithIntroOffer)

        expect(handler.purchaseResult) == .cancelled
        expect(handler.sessionPurchaseResult) == .cancelled
        expect(handler.purchaseError).to(beNil())
    }

    func testPurchaseErrorEventContainsProductIdentifierWhenCompletedByRevenueCat() async throws {
        let error: ErrorCode = .storeProblemError
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])

        let purchases = MockPurchases { _, _, _ in
            throw error
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { event in
            trackedEvents.modify { $0.append(event) }
        } customerInfo: {
            return TestData.customerInfo
        }
        let handler = PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(purchases: purchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil
        )
        handler.trackPaywallImpression(eventData)

        do {
            _ = try await handler.purchase(package: TestData.packageWithIntroOffer)
            fail("Expected error")
        } catch {}

        await expect(trackedEvents.value.contains(where: {
            if case .purchaseError = $0 { return true }
            return false
        })).toEventually(beTrue(), timeout: .seconds(2))

        let errorEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .purchaseError = $0 { return true }
            return false
        }))
        expect(errorEvent.data.productId) == TestData.packageWithIntroOffer.storeProduct.productIdentifier
    }

    func testPurchaseErrorEventContainsProductIdentifierWhenCompletedByMyApp() async throws {
        let purchaseError = NSError(domain: "test", code: 1)
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])

        let purchases = MockPurchases(
            purchasesAreCompletedBy: .myApp
        ) { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { event in
            trackedEvents.modify { $0.append(event) }
        } customerInfo: {
            return TestData.customerInfo
        }
        let handler = PurchaseHandler(
            purchases: purchases,
            performPurchase: { _ in (userCancelled: false, error: purchaseError) },
            performRestore: { (success: true, error: nil) },
            eventTracker: .init(purchases: purchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil
        )
        handler.trackPaywallImpression(eventData)

        do {
            _ = try await handler.purchase(package: TestData.packageWithIntroOffer)
            fail("Expected error")
        } catch {}

        await expect(trackedEvents.value.contains(where: {
            if case .purchaseError = $0 { return true }
            return false
        })).toEventually(beTrue(), timeout: .seconds(2))

        let errorEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .purchaseError = $0 { return true }
            return false
        }))
        expect(errorEvent.data.productId) == TestData.packageWithIntroOffer.storeProduct.productIdentifier
    }

    func testPurchasePassesPaywallEventAsParameterWhenCompletedByRevenueCat() async throws {
        let mockPurchases = MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            return TestData.customerInfo
        }

        let handler = PurchaseHandler(
            purchases: mockPurchases,
            eventTracker: .init(purchases: mockPurchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil
        )
        handler.trackPaywallImpression(eventData)

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        // .revenueCat path passes paywallEvent as a parameter, NOT via caching
        expect(mockPurchases.lastPurchasePaywallEvent).toNot(beNil())
        expect(mockPurchases.cachedPurchaseDataByProductID).to(beEmpty())
    }

    func testPurchaseCachesPurchaseDataWhenCompletedByMyApp() async throws {
        let mockPurchases = MockPurchases(
            purchasesAreCompletedBy: .myApp
        ) { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            return TestData.customerInfo
        }

        let handler = PurchaseHandler(
            purchases: mockPurchases,
            performPurchase: { _ in (userCancelled: false, error: nil) },
            performRestore: { (success: true, error: nil) },
            eventTracker: .init(purchases: mockPurchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil
        )
        handler.trackPaywallImpression(eventData)

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        // .myApp path caches both offering context and paywall event
        let expectedProductId = TestData.packageWithIntroOffer.storeProduct.productIdentifier
        let cachedData = mockPurchases.cachedPurchaseDataByProductID[expectedProductId]
        expect(cachedData).toNot(beNil())
        expect(cachedData?.presentedOfferingContext.offeringIdentifier)
            == TestData.packageWithIntroOffer.presentedOfferingContext.offeringIdentifier
        expect(cachedData?.paywallEvent).toNot(beNil())
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

    func testExternalPurchasePreparationMarksThePaywallForAsLongAsItRuns() async throws {
        let handler: PurchaseHandler = .mock()

        await handler.withExternalPurchasePreparation {
            expect(handler.actionTypeInProgress) == .externalPurchasePreparation
        }

        expect(handler.actionInProgress) == false
    }

    /// A second tap can reach the wrapper before the first one has marked the paywall, and must not free it
    /// while Apple's notice from the first tap is still up.
    func testAnExternalPurchasePreparationDoesNotFreeThePaywallItDidNotMark() async throws {
        let handler: PurchaseHandler = .mock()

        await handler.withExternalPurchasePreparation {
            await handler.withExternalPurchasePreparation {}

            expect(handler.actionTypeInProgress) == .externalPurchasePreparation
        }

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

        handler.setRestored(TestData.customerInfo, success: false)

        expect(handler.restoredCustomerInfo?.customerInfo) === TestData.customerInfo
        expect(handler.restoredCustomerInfo?.success) == false
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
        expect(handler.hasPurchasedInSession) == false
        expect(handler.packageBeingPurchased).to(beNil())
        expect(handler.actionInProgress) == false
        expect(handler.restoreInProgress) == false
        expect(handler.restoreError).to(matchError(error))
        expect(handler.purchaseError).to(beNil())
    }

    func testCloseEventIsTrackedOnlyAfterImpressionAndOnlyOnce() async throws {
        let handler: PurchaseHandler = .mock()

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil
        )

        let result1 = handler.trackPaywallClose()
        expect(result1) == false

        handler.trackPaywallImpression(eventData)

        let result2 = handler.trackPaywallClose()
        expect(result2) == true
        let result3 = handler.trackPaywallClose()
        expect(result3) == false

    }

    func testTrackPaywallCloseBySessionClosesThatSpecificSessionNotJustTheActiveOne() async throws {
        let handler: PurchaseHandler = .mock()

        func impressionData(_ sessionID: PaywallEvent.SessionID) -> PaywallEvent.Data {
            return .init(
                paywallIdentifier: TestData.paywallWithIntroOffer.id,
                offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
                paywallRevision: TestData.paywallWithIntroOffer.revision,
                sessionID: sessionID,
                displayMode: .fullScreen,
                localeIdentifier: "en_US",
                darkMode: false,
                source: nil
            )
        }

        let sessionA: PaywallEvent.SessionID = .init()
        let sessionB: PaywallEvent.SessionID = .init()

        // Two paywall pages are impressed (as in a workflow). `activePaywallSessionID` now points at B.
        handler.trackPaywallImpression(impressionData(sessionA))
        handler.trackPaywallImpression(impressionData(sessionB))

        // The earlier session (A) must still be closeable by id, even though it is not the active one.
        // `trackPaywallClose()` (no arg) would only ever close B, leaving A dangling open.
        expect(handler.trackPaywallClose(sessionID: sessionA)) == true
        expect(handler.trackPaywallClose(sessionID: sessionB)) == true

        // Closing an already-closed session is a no-op.
        expect(handler.trackPaywallClose(sessionID: sessionA)) == false
    }

    func testClearActivePaywallSessionMakesPurchaseEventsUnattributed() async throws {
        let handler: PurchaseHandler = .mock()

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: nil
        )

        // A paywall step is impressed, so purchase events resolve against its session.
        handler.trackPaywallImpression(eventData)
        expect(handler.createPurchaseInitiatedEvent(package: TestData.packageWithIntroOffer)).toNot(beNil())

        // Navigating onto a non-paywall workflow step clears the active session (see the gate in
        // `PaywallsV2View.firePaywallImpression`). A purchase there is now unattributed rather than
        // charged to the prior paywall step's session.
        handler.clearActivePaywallSession()
        expect(handler.createPurchaseInitiatedEvent(package: TestData.packageWithIntroOffer)).to(beNil())
    }

    func testPaywallSourceIsPropagatedToTrackedEvents() async throws {
        let source = PaywallSource.customerCenter
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])

        let purchases = MockPurchases(
            purchase: { _, _, _ in
            return (
                transaction: nil,
                customerInfo: TestData.customerInfo,
                userCancelled: false
            )
        },
            restorePurchases: {
            return TestData.customerInfo
        },
            trackEvent: { event in
            trackedEvents.modify { $0.append(event) }
        },
            customerInfo: {
            return TestData.customerInfo
        })
        let handler = PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(purchases: purchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )

        let eventData = PaywallEvent.Data(
            paywallIdentifier: TestData.paywallWithIntroOffer.id,
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: TestData.paywallWithIntroOffer.revision,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false,
            source: source
        )

        handler.trackPaywallImpression(eventData)

        let result = handler.trackPaywallClose()
        expect(result) == true

        await expect(trackedEvents.value).toEventually(haveCount(2), timeout: .seconds(2))
        trackedEvents.value.forEach { event in
            expect(event.data.source) == source
        }
    }

    func test_dedupedSubmissions_ofPurchaseCompletedEvents() async throws {
        let handler: PurchaseHandler = .mock(purchaseResultPublisher: purchaseResultPublisher)

        var count = 0

        let job = handler.$purchaseResult
            .drop(while: { $0 == nil })
            .sink { _ in
                count += 1
            }

        let transaction = StoreTransaction(MockStoreTransaction())
        for _ in 0...10 {
            purchaseResult.send((transaction, TestData.customerInfo, false))
            await Task.yield()
        }

        XCTAssertEqual(count, 1, "setting this should have only ouccured once from \(job)")

        let transaction2 = StoreTransaction(MockStoreTransaction())
        for _ in 0...10 {
            purchaseResult.send((transaction2, TestData.customerInfo, false))
            await Task.yield()
        }

        XCTAssertEqual(count, 2, "setting this should have only ouccured twice from \(job)")
    }

    func test_haveBothBeenCanceled_appliesCorrectly() async throws {
        let successfulPurchaseResult: PurchaseResultData = (
            transaction: nil,
            customerInfo: TestData.customerInfo,
            userCancelled: false
        )
        let cancelledPurchaseResult: PurchaseResultData = (
            transaction: nil,
            customerInfo: TestData.customerInfo,
            userCancelled: true
        )

        let testCases = [
            (
                shouldUpdate: false,
                currentResultState: nil as PurchaseResultData?,
                nextResultState: successfulPurchaseResult as PurchaseResultData?,
                line: #line as UInt
            ),
            (false, nil, cancelledPurchaseResult, #line),
            (false, successfulPurchaseResult, nil, #line),
            (false, cancelledPurchaseResult, nil, #line),
            (false, successfulPurchaseResult, successfulPurchaseResult, #line),
            (false, successfulPurchaseResult, cancelledPurchaseResult, #line),
            (false, cancelledPurchaseResult, successfulPurchaseResult, #line),
            (true, cancelledPurchaseResult, cancelledPurchaseResult, #line)
        ]

        for (shouldUpdate, currentResultState, nextResultState, line) in testCases {
            // GIVEN
            let purchaseResult = Atomic<PurchaseResultData>(successfulPurchaseResult)
            let purchases = MockPurchases { _, _, _ in
                purchaseResult.value
            } restorePurchases: {
                TestData.customerInfo
            } trackEvent: { event in
                Logger.debug("Tracking event: \(event)")
            } customerInfo: {
                TestData.customerInfo
            }

            let handler = PurchaseHandler(
                purchases: purchases,
                eventTracker: .init(purchases: purchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
            )

            var publishedRequestIDs: [UUID?] = []

            let cancellable = handler.$consecutiveCancellationRequestID
                .sink { publishedRequestIDs.append($0) }

            if let currentResultState {
                purchaseResult.value = currentResultState
                try await handler.purchase(package: TestData.packageWithIntroOffer)
            }

            publishedRequestIDs.removeAll()

            // WHEN
            if let nextResultState {
                purchaseResult.value = nextResultState
                try await handler.purchase(package: TestData.packageWithIntroOffer)
            } else {
                handler.resetForNewSession()
            }

            // THEN
            let didUpdate = publishedRequestIDs.contains { $0 != nil }
            XCTAssertEqual(didUpdate, shouldUpdate, line: line)

            // cleanup
            cancellable.cancel()
        }
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
        let purchases = MockPurchases { [weak instance = self] _, _, _ in
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
        self.purchaseHandler = .init(
            purchases: purchases,
            eventTracker: .init(purchases: purchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
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

    static func handlerFailingToFetchCustomerInfo(
        purchasesAreCompletedBy: PurchasesAreCompletedBy,
        performPurchase: PerformPurchase?
    ) -> PurchaseHandler {
        let purchases = MockPurchases(purchasesAreCompletedBy: purchasesAreCompletedBy) { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: true)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            throw ErrorCode.networkError
        }

        return PurchaseHandler(
            purchases: purchases,
            performPurchase: performPurchase,
            eventTracker: .init(purchases: purchases, eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )
    }

}

#endif

#if os(macOS)

@available(macOS 12.0, *)
@MainActor
final class PurchaseHandlerMacOSTests: TestCase {

    func testResignsFirstResponderBeforePublishingActionInProgress() async throws {
        var events: [String] = []
        let focusResigner = KeyWindowFocusResignerSpy {
            events.append("resigned")
        }
        let purchases = MockPurchases { _, _, _ in
            return (
                transaction: nil,
                customerInfo: TestData.customerInfo,
                userCancelled: false
            )
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            return TestData.customerInfo
        }
        let handler = PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(
                purchases: purchases,
                eventDispatcher: PaywallEventTrackerTestDispatcher.value
            ),
            keyWindowFocusResigner: focusResigner
        )
        let cancellable = handler.$actionTypeInProgress
            .dropFirst()
            .compactMap { $0 }
            .sink { _ in
                events.append("published")
            }

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        expect(events.prefix(2)) == ["resigned", "published"]
        withExtendedLifetime(cancellable) {}
    }

}

@available(macOS 12.0, *)
@MainActor
private final class KeyWindowFocusResignerSpy: KeyWindowFocusResigning {

    private let onResign: () -> Void

    init(onResign: @escaping () -> Void) {
        self.onResign = onResign
    }

    func resignFirstResponder() {
        self.onResign()
    }

}

#endif

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
@available(iOS 15.0, *)
private final class ContextPurchaseHandlerSpy: NSObject, PaywallPurchaseHandlerWithContext {

    var context: PaywallPurchaseContext?

    func performPurchase(with context: PaywallPurchaseContext,
                         completion: @escaping (Bool, Error?) -> Void) {
        self.context = context
        completion(true, ErrorCode.storeProblemError)
    }

    func performRestore(completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }

}
#endif
