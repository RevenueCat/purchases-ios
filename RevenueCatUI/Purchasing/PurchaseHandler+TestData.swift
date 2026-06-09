//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHandler+TestData.swift
//
//  Created by Nacho Soto on 9/12/23.

import Combine
import Foundation
@_spi(Internal) import RevenueCat

#if DEBUG

/// Uses `Task { }` so paywall events reach `MockPurchases.track` promptly. The production
/// ``PaywallEventTracker/dispatcher()`` uses `Task.detached(priority: .background)`, which can delay
/// delivery enough that XCTest expectations time out.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private let paywallEventMockDispatcher: PaywallEventTracker.EventDispatcher = { work in
    Task { await work() }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchaseHandler {

    static func mock(
        _ customerInfo: CustomerInfo = TestData.customerInfo,
        purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil,
        preferredLocaleOverride: String? = nil,
        stubbedOfferings: Offerings? = nil,
        stubbedWorkflow: WorkflowDataResult? = nil,
        purchaseResultPublisher: AnyPublisher<PurchaseResultData, Never> = Just(
            (
                transaction: nil,
                customerInfo: TestData.customerInfo,
                userCancelled: false
            )
        )
        .dropFirst()
        .eraseToAnyPublisher()
    ) -> Self {
        let purchases = MockPurchases(
            purchasesAreCompletedBy: purchasesAreCompletedBy,
            preferredLocaleOverride: preferredLocaleOverride
        ) { _, _, _ in
                return (
                    // No current way to create a mock transaction with RevenueCat's public methods.
                    transaction: nil,
                    customerInfo: customerInfo,
                    userCancelled: false
                )
            } restorePurchases: {
                return customerInfo
            } trackEvent: { event in
                Logger.debug("Tracking event: \(event)")
            } customerInfo: {
                return customerInfo
            }
        Self.applyWorkflowStub(to: purchases, offerings: stubbedOfferings, workflow: stubbedWorkflow)
        return self.init(
            purchases: purchases,
            performPurchase: performPurchase,
            performRestore: performRestore,
            purchaseResultPublisher: purchaseResultPublisher,
            eventTracker: .init(purchases: purchases, eventDispatcher: paywallEventMockDispatcher)
        )
    }

    /// Creates a mock `PurchaseHandler` that is already in the purchasing state.
    static func purchasing(package: Package = TestData.annualPackage) -> Self {
        let handler = Self.mock()
        handler.actionTypeInProgress = .purchase
        handler.packageBeingPurchased = package
        return handler
    }

    static func cancelling(
        purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat,
        stubbedOfferings: Offerings? = nil,
        stubbedWorkflow: WorkflowDataResult? = nil
    ) -> Self {
        // `.map` below copies the workflow/offerings stubs onto the derived mock, so stubbing here
        // is preserved through the cancellation wrapper.
        return .mock(
            purchasesAreCompletedBy: purchasesAreCompletedBy,
            stubbedOfferings: stubbedOfferings,
            stubbedWorkflow: stubbedWorkflow
        )
            .map { block in { package, offer, event in
                    var result = try await block(package, offer, event)
                    result.userCancelled = true
                    return result
                }
            } restore: { $0 }
    }

    /// - Returns: `PurchaseHandler` that throws `error` for purchases and restores.
    static func failing(
        _ error: Error,
        stubbedOfferings: Offerings? = nil,
        stubbedWorkflow: WorkflowDataResult? = nil
    ) -> Self {
        let purchases = MockPurchases { _, _, _ in
            throw error
        } restorePurchases: {
            throw error
        } trackEvent: { event in
            Logger.debug("Tracking event: \(event)")
        } customerInfo: {
            throw error
        }
        Self.applyWorkflowStub(to: purchases, offerings: stubbedOfferings, workflow: stubbedWorkflow)
        return self.init(
            purchases: purchases,
            eventTracker: .init(purchases: purchases, eventDispatcher: paywallEventMockDispatcher)
        )
    }

    /// Wires a default workflow + offerings onto `purchases` so a `PaywallView(offering:)` renders
    /// in the always-on-workflows world. Both the synchronous seed (`cachedWorkflow`/`cachedOfferings`)
    /// and the async resolve path are covered.
    private static func applyWorkflowStub(
        to purchases: MockPurchases,
        offerings: Offerings?,
        workflow: WorkflowDataResult?
    ) {
        if let offerings {
            purchases.cachedOfferings = offerings
            purchases.offeringsBlock = { offerings }
        }
        #if !os(tvOS)
        if let workflow {
            purchases.workflowBlock = { _ in workflow }
            purchases.cachedWorkflowBlock = { _ in workflow }
        }
        #endif
    }

    /// Creates a copy of this `PurchaseHandler` with a delay.
    func with(delay seconds: TimeInterval) -> Self {
        return self.map { purchaseBlock in { package, offer, event in
            await Task.sleep(seconds: seconds)

            return try await purchaseBlock(package, offer, event)
        }
        } restore: { restoreBlock in {
            await Task.sleep(seconds: seconds)

            return try await restoreBlock()
        }
        }
    }

}

extension Task where Success == Never, Failure == Never {

    static func sleep(seconds: TimeInterval) async {
        try? await Self.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

}

#endif
