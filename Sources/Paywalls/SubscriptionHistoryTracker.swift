//
//  SubscriptionHistoryTracker.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 31/7/25.
//

import Combine
import StoreKit

// swiftlint:disable missing_docs

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@_spi(Internal) public actor SubscriptionHistoryTracker {

    @_spi(Internal) public enum Status: Equatable, Sendable {
        case hasHistory
        case noHistory
        case unknown
    }

    @_spi(Internal) public var status: AnyPublisher<Status, Never> {
        return statusSubject.removeDuplicates().eraseToAnyPublisher()
    }

    private let statusSubject: CurrentValueSubject<Status, Never>
    private var cancellables = Set<AnyCancellable>()
    private var transactionUpdateTask: Task<Void, Never>?

    @_spi(Internal) public init() {
        guard #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) else {
            self.statusSubject = CurrentValueSubject(.unknown)
            return
        }

        self.statusSubject = CurrentValueSubject(.noHistory)

        Task {
            await initialize()
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func initialize() {
        self.evaluateSubscriptionHistory()

        self.transactionUpdateTask = Task { [weak self] in
            for await _ in StoreKit.Transaction.updates {
                await self?.evaluateSubscriptionHistory()
            }
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func evaluateSubscriptionHistory() {
        Task {
            var found = await StoreKit.Transaction.currentEntitlements.contains { result in
                result.isVerifiedAutoRenewable
            }

            if !found {
                found = await StoreKit.Transaction.all.contains { result in
                    result.isVerifiedAutoRenewable
                }
            }

            self.statusSubject.value = found ? .hasHistory : .noHistory
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension StoreKit.VerificationResult<StoreKit.Transaction> {

    var isVerifiedAutoRenewable: Bool {
        if case .verified(let transaction) = self {
            return transaction.productType == .autoRenewable
        }
        return false
    }

}
