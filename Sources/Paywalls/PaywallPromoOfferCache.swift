//
//  PaywallPromoOfferCache.swift
//  RevenueCat
//
//  Created by Josh Holtz on 6/17/25.
//
// swiftlint:disable missing_docs

import Combine
import StoreKit

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class SubscriptionHistoryTracker {

    public struct Update: Equatable {
        public let hasAnySubscriptionHistory: Bool
    }

    public let updateSubject = CurrentValueSubject<Update, Never>(.init(hasAnySubscriptionHistory: false))

    private var cancellables = Set<AnyCancellable>()
    private var transactionUpdateTask: Task<Void, Never>?

    public init() {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            evaluateSubscriptionHistory()

            transactionUpdateTask = Task {
                for await _ in StoreKit.Transaction.updates {
                    self.evaluateSubscriptionHistory()
                }
            }
        }
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    private func evaluateSubscriptionHistory() {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            Task {
                var found = false

                for await result in StoreKit.Transaction.currentEntitlements {
                    if case .verified(let transaction) = result,
                       transaction.productType == .autoRenewable {
                        found = true
                        break
                    }
                }

                if !found {
                    for await result in StoreKit.Transaction.all {
                        if case .verified(let transaction) = result,
                           transaction.productType == .autoRenewable {
                            found = true
                            break
                        }
                    }
                }

                self.updateSubject.send(.init(hasAnySubscriptionHistory: found))
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@_spi(Internal)
public actor SubscriptionHistoryObserver {

    public enum Status: Equatable {
        case unknown
        case hasHistory
        case noHistory
    }

    public private(set) var status: Status = .unknown

    private var subscriptionTracker: Any?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            let tracker = SubscriptionHistoryTracker()
            self.subscriptionTracker = tracker
            Task { [weak self]in
                await self?.bind(tracker)
            }
        } else {
            // On older versions, we don't have access to SK2
            self.status = .unknown
        }
    }

    func setStatus(_ newStatus: Status) {
        self.status = newStatus
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func bind(_ tracker: SubscriptionHistoryTracker) {
        tracker.updateSubject
            .map { $0.hasAnySubscriptionHistory ? Status.hasHistory : Status.noHistory }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                Task { [weak self] in
                    await self?.setStatus(status)
                }
            }
            .store(in: &cancellables)
    }
}
