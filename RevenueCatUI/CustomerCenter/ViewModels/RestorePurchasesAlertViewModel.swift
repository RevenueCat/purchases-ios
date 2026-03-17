//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RestorePurchasesAlertViewModel.swift
//
//  Created by Cesar de la Vega on 28/3/25.

import Foundation
import SwiftUI

private let defaultRestoreInitiatedTimeoutNanoseconds: UInt64 = 60_000_000_000

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor class RestorePurchasesAlertViewModel: ObservableObject {

    @Published
    var alertType: RestorePurchasesAlertViewModel.AlertType = .loading

    private let actionWrapper: CustomerCenterActionWrapper
    private let restoreInitiatedTimeoutNanoseconds: UInt64

    enum AlertType: Identifiable {
        case loading, purchasesRecovered, purchasesNotFound
        var id: Self { self }
    }

    init(
        purchasesProvider: CustomerCenterPurchasesType = CustomerCenterPurchases(),
        actionWrapper: CustomerCenterActionWrapper,
        restoreInitiatedTimeoutNanoseconds: UInt64 = defaultRestoreInitiatedTimeoutNanoseconds
    ) {
        self.actionWrapper = actionWrapper
        self.restoreInitiatedTimeoutNanoseconds = restoreInitiatedTimeoutNanoseconds
    }

    func performRestore(
        purchasesProvider: CustomerCenterPurchasesType,
        restoreInitiated: @escaping @MainActor @Sendable (ResumeAction) -> Void
    ) async -> Bool {
        self.alertType = .loading

        let shouldProceed = await withCheckedContinuation { continuation in
            let resume = self.singleUseResumeAction(for: continuation)

            Task { @MainActor [restoreInitiatedTimeoutNanoseconds = self.restoreInitiatedTimeoutNanoseconds] in
                try? await Task.sleep(nanoseconds: restoreInitiatedTimeoutNanoseconds)
                resume(shouldProceed: true)
            }

            // Legacy action handlers should take precedence over environment callbacks.
            if self.actionWrapper.hasLegacyActionHandler {
                self.actionWrapper.handleAction(.restoreInitiated(resume))
            } else {
                restoreInitiated(resume)
            }
        }

        guard shouldProceed else {
            return false
        }

        self.actionWrapper.handleAction(.restoreStarted)

        do {
            // In case the restore finishes instantly, we make sure it lasts at least 0.5 seconds
            let (customerInfo, _) = try await (purchasesProvider.restorePurchases(),
                                               Task.sleep(nanoseconds: 500_000_000))
            self.actionWrapper.handleAction(.restoreCompleted(customerInfo))

            let hasPurchases = !customerInfo.activeSubscriptions.isEmpty || !customerInfo.nonSubscriptions.isEmpty
            self.alertType = hasPurchases ? .purchasesRecovered : .purchasesNotFound
        } catch {
            self.actionWrapper.handleAction(.restoreFailed(error))
            self.alertType = .purchasesNotFound
        }

        return true
    }

    private func singleUseResumeAction(for continuation: CheckedContinuation<Bool, Never>) -> ResumeAction {
        final class ResumeState: @unchecked Sendable {
            private let lock = NSLock()
            private var didResume = false

            func tryResume(
                shouldProceed: Bool,
                continuation: CheckedContinuation<Bool, Never>
            ) {
                self.lock.lock()
                defer { self.lock.unlock() }

                guard !self.didResume else { return }
                self.didResume = true
                continuation.resume(returning: shouldProceed)
            }
        }

        let state = ResumeState()

        let resume = ResumeAction(action: { shouldProceed in
            state.tryResume(shouldProceed: shouldProceed, continuation: continuation)
        })

        return resume
    }

}
