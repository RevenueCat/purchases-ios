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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchaseHandler {

    static func mock(
        _ customerInfo: CustomerInfo = TestData.customerInfo,
        purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil,
        preferredLocaleOverride: String? = nil,
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
        return self.init(
            purchases: purchases,
            eventDispatcher: Self.testEventDispatcher,
            performPurchase: performPurchase,
            performRestore: performRestore,
            purchaseResultPublisher: purchaseResultPublisher
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
        purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat
    ) -> Self {
        return .mock(purchasesAreCompletedBy: purchasesAreCompletedBy)
            .map { block in { package, offer, event in
                    var result = try await block(package, offer, event)
                    result.userCancelled = true
                    return result
                }
            } restore: { $0 }
    }

    /// - Returns: `PurchaseHandler` that throws `error` for purchases and restores.
    static func failing(_ error: Error) -> Self {
        return self.init(
            purchases: MockPurchases { _, _, _ in
                throw error
            } restorePurchases: {
                throw error
            } trackEvent: { event in
                Logger.debug("Tracking event: \(event)")
            } customerInfo: {
                throw error
            },
            eventDispatcher: Self.testEventDispatcher
        )
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchaseHandler {

    /// Test event dispatcher that uses `Task { }` instead of `Task.detached(priority: .background)`.
    /// Non-detached tasks inherit the caller's actor context and priority, so events are delivered
    /// promptly without the aggressive deprioritization that `Task.detached(priority: .background)`
    /// causes on iOS 26+ CI environments.
    static let testEventDispatcher: EventDispatcher = { work in
        Task { await work() }
    }

}

#endif
