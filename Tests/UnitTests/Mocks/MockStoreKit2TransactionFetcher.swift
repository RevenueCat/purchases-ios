//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2TransactionFetcher.swift
//
//  Created by Nacho Soto on 5/23/23.

import Foundation
@testable import RevenueCat

final class MockStoreKit2TransactionFetcher: StoreKit2TransactionFetcherType {

    private let _stubbedUnfinishedTransactions: Atomic<[StoreTransaction]> = .init([])
    private let _stubbedFirstVerifiedTransaction: Atomic<StoreTransaction?> = .init(nil)
    private let _stubbedFirstVerifiedAutoRenewableTransaction: Atomic<StoreTransaction?> = .init(nil)
    private let _stubbedHasPendingConsumablePurchase: Atomic<Bool> = false
    private let _stubbedReceipt: Atomic<StoreKit2Receipt?> = .init(nil)
    private let _stubbedAppTransactionJWS: Atomic<String?> = .init(nil)

    var stubbedUnfinishedTransactions: [StoreTransaction] {
        get { return self._stubbedUnfinishedTransactions.value }
        set { self._stubbedUnfinishedTransactions.value = newValue }
    }

    var stubbedFirstVerifiedTransaction: StoreTransaction? {
        get { return self._stubbedFirstVerifiedTransaction.value }
        set { self._stubbedFirstVerifiedTransaction.value = newValue }
    }

    var stubbedReceipt: StoreKit2Receipt? {
        get { return self._stubbedReceipt.value }
        set { self._stubbedReceipt.value = newValue }
    }

    var stubbedFirstVerifiedAutoRenewableTransaction: StoreTransaction? {
        get { return self._stubbedFirstVerifiedAutoRenewableTransaction.value }
        set { self._stubbedFirstVerifiedAutoRenewableTransaction.value = newValue }
    }

    var stubbedAppTransactionJWS: String? {
        get { return self._stubbedAppTransactionJWS.value }
        set { self._stubbedAppTransactionJWS.value = newValue }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var unfinishedVerifiedTransactions: [StoreTransaction] {
        get async {
            return self.stubbedUnfinishedTransactions
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func fetchReceipt(containing transaction: StoreTransactionType) async -> StoreKit2Receipt {
        return self.stubbedReceipt!
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedTransaction: RevenueCat.StoreTransaction? {
        get async {
            self.stubbedFirstVerifiedTransaction
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedAutoRenewableTransaction: RevenueCat.StoreTransaction? {
        get async {
            self.stubbedFirstVerifiedAutoRenewableTransaction
        }
    }

    let appTransactionJWSCalled = Atomic<Bool>(false)
    var appTransactionJWS: String? {
        get async {
            self.appTransactionJWSCalled.value = true
            return self.stubbedAppTransactionJWS
        }
    }

    func appTransactionJWS(_ completion: @escaping (String?) -> Void) {
        self.appTransactionJWSCalled.value = true
        completion(self.stubbedAppTransactionJWS)
    }

    // MARK: - AppTransaction Environment

    private let _stubbedAppTransactionEnvironment: Atomic<StoreEnvironment?> = .init(nil)

    var stubbedAppTransactionEnvironment: StoreEnvironment? {
        get { return self._stubbedAppTransactionEnvironment.value }
        set { self._stubbedAppTransactionEnvironment.value = newValue }
    }

    let appTransactionEnvironmentCalled = Atomic<Bool>(false)

    /// When set to true, `appTransactionEnvironment` will stall until `resumeAppTransactionEnvironment()` is called.
    let appTransactionEnvironmentShouldStall = Atomic<Bool>(false)

    // Keep continuation + resume flag in one atomic state to avoid resume-before-wait
    // and double-resume races between the getter and resumeAppTransactionEnvironment().
    private struct AppTransactionStallState {
        var continuation: CheckedContinuation<Void, Never>?
        var resumeRequested: Bool
    }

    private let _appTransactionStallState: Atomic<AppTransactionStallState> = .init(
        .init(continuation: nil, resumeRequested: false)
    )

    /// Resumes the stalled `appTransactionEnvironment` getter.
    func resumeAppTransactionEnvironment() {
        // Atomically decide whether to resume now or record a pending resume.
        let continuationToResume: CheckedContinuation<Void, Never>? = self._appTransactionStallState.modify { state in
            state.resumeRequested = true

            if let continuation = state.continuation {
                state.resumeRequested = false
                state.continuation = nil
                return continuation
            }

            return nil
        }

        continuationToResume?.resume()
    }

    var appTransactionEnvironment: StoreEnvironment? {
        get async {
            self.appTransactionEnvironmentCalled.value = true

            if self.appTransactionEnvironmentShouldStall.value {
                // Stalling until resumeAppTransactionEnvironment() is called
                await withCheckedContinuation { continuation in
                    // Atomically decide whether to store the continuation or immediately resume it
                    // if a resume was already requested.
                    let continuationToResume: CheckedContinuation<Void, Never>? = self._appTransactionStallState
                        .modify { state in
                        if state.resumeRequested {
                            state.resumeRequested = false
                            return continuation
                        }

                        state.continuation = continuation
                        return nil
                    }

                    continuationToResume?.resume()
                }
            }

            return self.stubbedAppTransactionEnvironment
        }
    }

    func appTransactionEnvironment(_ completion: @escaping (StoreEnvironment?) -> Void) {
        self.appTransactionEnvironmentCalled.value = true
        completion(self.stubbedAppTransactionEnvironment)
    }

    // MARK: -

    var stubbedHasPendingConsumablePurchase: Bool {
        get { return self._stubbedHasPendingConsumablePurchase.value }
        set { self._stubbedHasPendingConsumablePurchase.value = newValue }
    }

    var hasPendingConsumablePurchase: Bool {
        return self.stubbedHasPendingConsumablePurchase
    }

}
