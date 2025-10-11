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
        return self.init(
            purchases: MockPurchases(purchasesAreCompletedBy: purchasesAreCompletedBy,
                                     preferredLocaleOverride: preferredLocaleOverride) { _ in
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
            },
            performPurchase: performPurchase,
            performRestore: performRestore,
            purchaseResultPublisher: purchaseResultPublisher
        )
    }

    static func cancelling(purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat) -> Self {
        return .mock(purchasesAreCompletedBy: purchasesAreCompletedBy)
            .map { block in {
                    var result = try await block($0)
                    result.userCancelled = true
                    return result
                }
            } restore: { $0 }
    }

    /// - Returns: `PurchaseHandler` that throws `error` for purchases and restores.
    static func failing(_ error: Error) -> Self {
        return self.init(
            purchases: MockPurchases { _ in
                throw error
            } restorePurchases: {
                throw error
            } trackEvent: { event in
                Logger.debug("Tracking event: \(event)")
            } customerInfo: {
                throw error
            }
        )
    }

    /// Creates a copy of this `PurchaseHandler` with a delay.
    func with(delay seconds: TimeInterval) -> Self {
        return self.map { purchaseBlock in {
            await Task.sleep(seconds: seconds)

            return try await purchaseBlock($0)
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
