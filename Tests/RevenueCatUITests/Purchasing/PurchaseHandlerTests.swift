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

    #if !os(tvOS)
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
    #endif

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

    #if !os(tvOS)
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
    #endif

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

    #if !os(tvOS)
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

    #endif

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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class CustomPurchaseCompatibilityTests: TestCase {

    func testLegacyPurchaseSuccessWithAndWithoutOffer() async throws {
        try await self.checkPurchase(usesContext: false, userCancelled: false, error: nil)
    }

    func testContextPurchaseSuccessWithAndWithoutOffer() async throws {
        try await self.checkPurchase(usesContext: true, userCancelled: false, error: nil)
    }

    func testLegacyPurchaseCancellationWithAndWithoutOffer() async throws {
        try await self.checkPurchase(usesContext: false, userCancelled: true, error: nil)
    }

    func testContextPurchaseCancellationWithAndWithoutOffer() async throws {
        try await self.checkPurchase(usesContext: true, userCancelled: true, error: nil)
    }

    func testLegacyPurchaseFailureWithAndWithoutOffer() async throws {
        try await self.checkPurchase(usesContext: false, userCancelled: false, error: Self.purchaseError)
    }

    func testContextPurchaseFailureWithAndWithoutOffer() async throws {
        try await self.checkPurchase(usesContext: true, userCancelled: false, error: Self.purchaseError)
    }

    func testLegacyCancellationWithErrorPreservesErrorPrecedence() async throws {
        try await self.checkPurchase(usesContext: false, userCancelled: true, error: Self.purchaseError)
    }

    func testContextCancellationWithErrorPreservesErrorPrecedence() async throws {
        try await self.checkPurchase(usesContext: true, userCancelled: true, error: Self.purchaseError)
    }

    func testCustomerInfoFailureDoesNotRepeatEitherCustomPurchase() async throws {
        for usesContext in [false, true] {
            var purchaseCount = 0
            let expectedError = Self.purchaseError
            let purchases = Self.purchases(customerInfo: { throw expectedError })
            let callback: PerformPurchase = { _ in
                purchaseCount += 1
                return (userCancelled: false, error: nil)
            }
            let contextCallback: PerformPurchaseWithContext = { context in await callback(context.package) }
            let handler = PurchaseHandler(
                purchases: purchases,
                performPurchase: usesContext ? nil : callback,
                performPurchaseWithContext: usesContext ? contextCallback : nil,
                eventTracker: .init(purchases: purchases)
            )

            do {
                try await handler.purchase(package: TestData.packageWithIntroOffer)
                XCTFail("Expected the customer info error")
            } catch {
                XCTAssertTrue(error as NSError === Self.purchaseError)
            }

            XCTAssertEqual(purchaseCount, 1)
            XCTAssertFalse(handler.actionInProgress)
            XCTAssertNil(handler.packageBeingPurchased)
            XCTAssertNotNil(purchases.cachedPurchaseDataByProductID[TestData.packageWithIntroOffer.storeProduct.id])
        }
    }

    func testRetryAfterCancellationOrFailureUsesFreshPurchaseContext() async throws {
        for firstResult in [(userCancelled: true, error: nil as Error?), (false, Self.purchaseError as Error?)] {
            var contexts: [PaywallPurchaseContext] = []
            let firstOffer = Self.offer(identifier: "first")
            let secondOffer = Self.offer(identifier: "second")
            let handler = PurchaseHandler.mock(purchasesAreCompletedBy: .myApp, performPurchaseWithContext: { context in
                contexts.append(context)
                return contexts.count == 1 ? firstResult : (userCancelled: false, error: nil)
            })
            do {
                try await handler.purchase(package: TestData.packageWithIntroOffer, promotionalOffer: firstOffer)
            } catch {
                XCTAssertTrue(error as NSError === Self.purchaseError)
            }
            XCTAssertNil(handler.packageBeingPurchased)

            try await handler.purchase(package: TestData.annualPackage, promotionalOffer: secondOffer)

            XCTAssertEqual(contexts.count, 2)
            XCTAssertTrue(contexts[0].package === TestData.packageWithIntroOffer)
            XCTAssertTrue(contexts[0].promotionalOffer === firstOffer)
            XCTAssertTrue(contexts[1].package === TestData.annualPackage)
            XCTAssertTrue(contexts[1].promotionalOffer === secondOffer)
            XCTAssertNil(handler.purchaseError)
            XCTAssertNil(handler.packageBeingPurchased)
            expect(handler.purchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
        }
    }

    #if !os(tvOS)
    func testContextCallbackSurvivesBothDefaultFactories() async throws {
        for throughLogic in [false, true] {
            var received: PaywallPurchaseContext?
            let callback: PerformPurchaseWithContext = { context in
                received = context
                return (true, Self.purchaseError)
            }
            let restore: PerformRestore = { (false, Self.purchaseError) }
            let handler: PurchaseHandler
            if throughLogic {
                handler = .default(myAppPurchaseLogic: .init(
                    performPurchaseWithContext: callback,
                    performRestore: restore
                ))
            } else {
                handler = .default(performRestore: restore, performPurchaseWithContext: callback)
            }
            let context = PaywallPurchaseContext(package: TestData.annualPackage,
                                                 promotionalOffer: Self.offer(identifier: "factory"))

            let result = await (try XCTUnwrap(handler.performPurchaseWithContext))(context)
            let restored = await (try XCTUnwrap(handler.performRestore))()

            XCTAssertTrue(received === context)
            XCTAssertTrue(result.userCancelled)
            XCTAssertTrue(result.error as NSError? === Self.purchaseError)
            XCTAssertFalse(restored.success)
            XCTAssertTrue(restored.error as NSError? === Self.purchaseError)
        }
    }

    func testLegacyMultipleTrailingClosuresPreserveResults() async {
        var purchaseCalls = 0
        var restoreCalls = 0
        let logic = MyAppPurchaseLogic { _ in
            purchaseCalls += 1
            return (userCancelled: true, error: Self.purchaseError)
        } performRestore: {
            restoreCalls += 1
            return (success: false, error: Self.purchaseError)
        }

        let result = await logic.performPurchaseWithContext(.init(
            package: TestData.annualPackage,
            promotionalOffer: Self.offer(identifier: "legacy-trailing")
        ))
        let restored = await logic.performRestore()

        XCTAssertEqual(purchaseCalls, 1)
        XCTAssertEqual(restoreCalls, 1)
        XCTAssertTrue(result.userCancelled)
        XCTAssertTrue(result.error as NSError? === Self.purchaseError)
        XCTAssertFalse(restored.success)
        XCTAssertTrue(restored.error as NSError? === Self.purchaseError)
    }

    func testUnlabeledPurchaseClosureKeepsReceivingPackage() async {
        var receivedArgument: Any?
        // Erase the argument's type so the callback body cannot influence overload selection.
        let logic = MyAppPurchaseLogic { argument in
            receivedArgument = argument
            return (userCancelled: true, error: nil)
        } performRestore: {
            (success: true, error: nil)
        }
        let context = PaywallPurchaseContext(package: TestData.annualPackage,
                                             promotionalOffer: Self.offer(identifier: "overload-selection"))

        _ = await logic.performPurchaseWithContext(context)

        XCTAssertTrue((receivedArgument as? Package) === context.package)
    }

    func testContextMultipleTrailingClosuresPreserveContextAndResults() async {
        var receivedContext: PaywallPurchaseContext?
        var restoreCalls = 0
        // Exercise the public trailing-closure syntax so overload regressions fail to compile.
        // swiftlint:disable multiple_closures_with_trailing_closure
        let logic = MyAppPurchaseLogic(performPurchaseWithContext: { context in
            receivedContext = context
            return (userCancelled: true, error: Self.purchaseError)
        }) {
            restoreCalls += 1
            return (success: false, error: Self.purchaseError)
        }
        // swiftlint:enable multiple_closures_with_trailing_closure
        let context = PaywallPurchaseContext(package: TestData.annualPackage,
                                             promotionalOffer: Self.offer(identifier: "context-trailing"))

        let result = await logic.performPurchaseWithContext(context)
        let restored = await logic.performRestore()

        XCTAssertTrue(receivedContext === context)
        XCTAssertTrue(result.userCancelled)
        XCTAssertTrue(result.error as NSError? === Self.purchaseError)
        XCTAssertEqual(restoreCalls, 1)
        XCTAssertFalse(restored.success)
        XCTAssertTrue(restored.error as NSError? === Self.purchaseError)
    }

    func testLegacyCallbackSurvivesBothDefaultFactories() async throws {
        for throughLogic in [false, true] {
            var received: Package?
            let callback: PerformPurchase = { package in
                received = package
                return (false, Self.purchaseError)
            }
            let handler: PurchaseHandler
            if throughLogic {
                handler = .default(myAppPurchaseLogic: .init(
                    performPurchase: callback,
                    performRestore: { (true, nil) }
                ))
            } else {
                handler = .default(performPurchase: callback)
            }
            let context = PaywallPurchaseContext(package: TestData.annualPackage,
                                                 promotionalOffer: Self.offer(identifier: "legacy"))

            let result = await (try XCTUnwrap(handler.performPurchaseWithContext))(context)

            XCTAssertTrue(received === context.package)
            XCTAssertFalse(result.userCancelled)
            XCTAssertTrue(result.error as NSError? === Self.purchaseError)
        }
    }

    func testNoCustomLogicLeavesBothCallbacksUnset() {
        let handler = PurchaseHandler.default(myAppPurchaseLogic: nil)
        XCTAssertNil(handler.performPurchaseWithContext)
        XCTAssertNil(handler.performRestore)
    }

    func testMyAppLogicAdaptersPreserveAllResults() async {
        for usesContext in [false, true] {
            for cancelled in [false, true] {
                for error in [nil, Self.purchaseError] {
                    var receivedPackage: Package?
                    var receivedOffer: PromotionalOffer?
                    let legacy: PerformPurchase = { package in
                        receivedPackage = package
                        return (cancelled, error)
                    }
                    let contextual: PerformPurchaseWithContext = { context in
                        receivedPackage = context.package
                        receivedOffer = context.promotionalOffer
                        return (cancelled, error)
                    }
                    let restore: PerformRestore = { (true, nil) }
                    let logic = usesContext
                        ? MyAppPurchaseLogic(performPurchaseWithContext: contextual, performRestore: restore)
                        : MyAppPurchaseLogic(performPurchase: legacy, performRestore: restore)
                    let offer = Self.offer(identifier: "adapter")
                    let result = await logic.performPurchaseWithContext(.init(package: TestData.annualPackage,
                                                                              promotionalOffer: offer))
                    XCTAssertTrue(receivedPackage === TestData.annualPackage)
                    XCTAssertTrue(receivedOffer === (usesContext ? offer : nil))
                    XCTAssertEqual(result.userCancelled, cancelled)
                    XCTAssertTrue(result.error as NSError? === error)

                    let legacyResult = await logic.performPurchase(TestData.packageWithIntroOffer)
                    XCTAssertTrue(receivedPackage === TestData.packageWithIntroOffer)
                    XCTAssertNil(receivedOffer)
                    XCTAssertEqual(legacyResult.userCancelled, cancelled)
                    XCTAssertTrue(legacyResult.error as NSError? === error)
                }
            }
        }
    }

    func testContextAwareLogicPreservesRestoreSuccessFailureAndErrors() async throws {
        for success in [false, true] {
            for error in [nil, Self.purchaseError] {
                var restoreCalls = 0
                let logic = MyAppPurchaseLogic(performPurchaseWithContext: { _ in
                    XCTFail("Restoring must not execute a purchase")
                    return (false, nil)
                }, performRestore: {
                    restoreCalls += 1
                    return (success, error)
                })
                let handler = PurchaseHandler.mock(
                    purchasesAreCompletedBy: .myApp,
                    performRestore: logic.performRestore,
                    performPurchaseWithContext: logic.performPurchaseWithContext
                )
                do {
                    let result = try await handler.restorePurchases()
                    XCTAssertNil(error)
                    XCTAssertEqual(result.success, success)
                    XCTAssertTrue(result.info === TestData.customerInfo)
                } catch let caught {
                    XCTAssertNotNil(error)
                    XCTAssertTrue(caught as NSError === error)
                }
                XCTAssertEqual(restoreCalls, 1)
                XCTAssertFalse(handler.restoreInProgress)
                XCTAssertFalse(handler.actionInProgress)
                XCTAssertEqual(handler.restoreError as NSError?, error)
            }
        }
    }
    #endif

    func testRevenueCatManagedPurchaseReceivesOfferWithoutCallingEitherCustomHandler() async throws {
        let received = Atomic<PaywallPurchaseContext?>(nil)
        let offer = Self.offer(identifier: "native")
        let purchases = Self.purchases(purchasesAreCompletedBy: .revenueCat, purchase: { package, offer, _ in
            received.value = .init(package: package, promotionalOffer: offer)
            return (nil, TestData.customerInfo, false)
        })
        let handler = PurchaseHandler(
            purchases: purchases,
            performPurchase: { _ in
                XCTFail("The legacy custom handler must not run")
                return (false, nil)
            },
            performPurchaseWithContext: { _ in
                XCTFail("The context custom handler must not run")
                return (false, nil)
            },
            eventTracker: .init(purchases: purchases)
        )

        try await handler.purchase(package: TestData.packageWithIntroOffer, promotionalOffer: offer)

        let context = try XCTUnwrap(received.value)
        XCTAssertTrue(context.package === TestData.packageWithIntroOffer)
        XCTAssertTrue(context.promotionalOffer === offer)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension CustomPurchaseCompatibilityTests {

    static let purchaseError = NSError(domain: "CustomPurchaseCompatibilityTests", code: 42)

    func checkPurchase(usesContext: Bool, userCancelled: Bool, error expectedError: NSError?) async throws {
        for offer in [nil, Self.offer(identifier: "selected")] {
            let infoCalls = Atomic(0)
            let purchases = Self.purchases(customerInfo: {
                infoCalls.modify { $0 += 1 }
                return TestData.customerInfo
            })
            let package = TestData.packageWithIntroOffer
            var callbackCount = 0
            weak var handlerReference: PurchaseHandler?
            let callback: PerformPurchaseWithContext = { context in
                callbackCount += 1
                XCTAssertTrue(context.package === package)
                XCTAssertTrue(context.promotionalOffer === (usesContext ? offer : nil))
                XCTAssertTrue(handlerReference?.packageBeingPurchased === package)
                XCTAssertTrue(handlerReference?.actionInProgress == true)
                let cached = purchases.cachedPurchaseDataByProductID[package.storeProduct.id]
                XCTAssertEqual(cached?.presentedOfferingContext.offeringIdentifier,
                               package.presentedOfferingContext.offeringIdentifier)
                XCTAssertNotNil(cached?.paywallEvent)
                return (userCancelled, expectedError)
            }
            let legacyCallback: PerformPurchase = { package in
                await callback(.init(package: package, promotionalOffer: nil))
            }
            let handler = PurchaseHandler(
                purchases: purchases,
                performPurchase: usesContext ? nil : legacyCallback,
                performPurchaseWithContext: usesContext ? callback : nil,
                eventTracker: .init(purchases: purchases)
            )
            handlerReference = handler
            handler.trackPaywallImpression(.init(
                paywallIdentifier: TestData.paywallWithIntroOffer.id,
                offeringIdentifier: package.presentedOfferingContext.offeringIdentifier,
                paywallRevision: TestData.paywallWithIntroOffer.revision,
                sessionID: .init(), displayMode: .fullScreen, localeIdentifier: "en_US", darkMode: false, source: nil
            ))

            do {
                try await handler.purchase(package: package, promotionalOffer: offer)
                XCTAssertNil(expectedError)
            } catch {
                XCTAssertNotNil(expectedError)
                XCTAssertTrue(error as NSError === expectedError)
            }

            XCTAssertEqual(callbackCount, 1)
            XCTAssertFalse(handler.actionInProgress)
            XCTAssertFalse(handler.restoreInProgress)
            XCTAssertNil(handler.packageBeingPurchased)
            XCTAssertEqual(infoCalls.value, expectedError == nil && !userCancelled ? 1 : 0)
            XCTAssertEqual(handler.purchaseError as NSError?, expectedError)
            if expectedError != nil {
                XCTAssertNil(handler.purchaseResult)
            } else if userCancelled {
                expect(handler.purchaseResult) == .cancelled
                expect(handler.sessionPurchaseResult) == .cancelled
            } else {
                expect(handler.purchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
                expect(handler.sessionPurchaseResult) == .purchased(
                    transaction: nil, customerInfo: TestData.customerInfo
                )
            }
            XCTAssertEqual(purchases.cachedPurchaseDataByProductID.isEmpty, userCancelled || expectedError != nil)
        }
    }

    static func purchases(
        purchasesAreCompletedBy: PurchasesAreCompletedBy = .myApp,
        purchase: @escaping MockPurchases.PurchaseBlock = { _, _, _ in
            XCTFail("RevenueCat must not make the app's purchase")
            return (nil, TestData.customerInfo, false)
        },
        customerInfo: @escaping MockPurchases.CustomerInfoBlock = { TestData.customerInfo }
    ) -> MockPurchases {
        return MockPurchases(
            purchasesAreCompletedBy: purchasesAreCompletedBy,
            purchase: purchase,
            restorePurchases: { TestData.customerInfo },
            trackEvent: { _ in },
            customerInfo: customerInfo
        )
    }

    static func offer(identifier: String) -> PromotionalOffer {
        return PromotionalOffer(
            discount: MockStoreProductDiscount(
                offerIdentifier: identifier, currencyCode: "USD", price: 1, localizedPriceString: "$1.00",
                paymentMode: .payAsYouGo, subscriptionPeriod: .init(value: 1, unit: .month),
                numberOfPeriods: 1, type: .promotional
            ),
            signedData: .init(identifier: identifier, keyIdentifier: "key", nonce: UUID(),
                              signature: "signature", timestamp: 1234)
        )
    }

}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
@available(iOS 15.0, *)
@MainActor
final class ObjCPurchaseCompatibilityTests: TestCase {

    func testLegacyBridgePreservesPurchaseAndRestoreResults() async throws {
        for cancelled in [false, true] {
            for error in [nil, NSError(domain: "ObjC legacy", code: 1)] {
                let spy = DualPurchaseHandlerSpy()
                spy.userCancelled = cancelled
                spy.error = error
                spy.restoreSuccess = !cancelled
                let bridged = PaywallViewController.bridgePurchaseHandler(spy)

                let purchased = await (try XCTUnwrap(bridged.performPurchase))(TestData.annualPackage)
                let restored = await (try XCTUnwrap(bridged.performRestore))()

                XCTAssertTrue(spy.package === TestData.annualPackage)
                XCTAssertNil(spy.context)
                XCTAssertEqual(spy.legacyCalls, 1)
                XCTAssertEqual(spy.contextCalls, 0)
                XCTAssertEqual(spy.restoreCalls, 1)
                XCTAssertEqual(purchased.userCancelled, cancelled)
                XCTAssertTrue(purchased.error as NSError? === error)
                XCTAssertEqual(restored.success, !cancelled)
                XCTAssertTrue(restored.error as NSError? === error)
            }
        }
    }

    func testContextBridgePreservesOfferPurchaseAndRestoreResults() async {
        for cancelled in [false, true] {
            for error in [nil, NSError(domain: "ObjC context", code: 2)] {
                for offer in [nil, CustomPurchaseCompatibilityTests.offer(identifier: "objc")] {
                    let spy = DualPurchaseHandlerSpy()
                    spy.userCancelled = cancelled
                    spy.error = error
                    spy.restoreSuccess = !cancelled
                    let bridged = PaywallViewController.bridgePurchaseHandlerWithContext(spy)
                    let context = PaywallPurchaseContext(package: TestData.annualPackage, promotionalOffer: offer)

                    let purchased = await bridged.performPurchaseWithContext(context)
                    let restored = await bridged.performRestore()

                    XCTAssertTrue(spy.context === context)
                    XCTAssertTrue(spy.context?.promotionalOffer === offer)
                    XCTAssertNil(spy.package)
                    XCTAssertEqual(spy.legacyCalls, 0)
                    XCTAssertEqual(spy.contextCalls, 1)
                    XCTAssertEqual(spy.restoreCalls, 1)
                    XCTAssertEqual(purchased.userCancelled, cancelled)
                    XCTAssertTrue(purchased.error as NSError? === error)
                    XCTAssertEqual(restored.success, !cancelled)
                    XCTAssertTrue(restored.error as NSError? === error)
                }
            }
        }
    }

    func testNilLegacyHandlerStillProducesNoCallbacks() {
        let bridged = PaywallViewController.bridgePurchaseHandler(nil)
        XCTAssertNil(bridged.performPurchase)
        XCTAssertNil(bridged.performRestore)
    }

}

@available(iOS 15.0, *)
private final class DualPurchaseHandlerSpy: NSObject, PaywallPurchaseHandler, PaywallPurchaseHandlerWithContext {

    var package: Package?
    var context: PaywallPurchaseContext?
    var userCancelled = false
    var error: NSError?
    var restoreSuccess = true
    var legacyCalls = 0
    var contextCalls = 0
    var restoreCalls = 0

    func performPurchase(for package: Package, completion: @escaping (Bool, Error?) -> Void) {
        self.package = package
        self.legacyCalls += 1
        completion(self.userCancelled, self.error)
    }

    func performPurchase(with context: PaywallPurchaseContext, completion: @escaping (Bool, Error?) -> Void) {
        self.context = context
        self.contextCalls += 1
        completion(self.userCancelled, self.error)
    }

    func performRestore(completion: @escaping (Bool, Error?) -> Void) {
        self.restoreCalls += 1
        completion(self.restoreSuccess, self.error)
    }

}
#endif
