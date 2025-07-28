//
//  PaywallPromoOfferCache.swift
//  RevenueCat
//
//  Created by Josh Holtz on 6/17/25.
//
// swiftlint:disable missing_docs

import Combine
import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class SubscriptionHistoryTracker {

    public struct Update: Equatable {
        public let hasAnySubscriptionHistory: Bool
    }

    public let updateSubject = CurrentValueSubject<Update, Never>(.init(hasAnySubscriptionHistory: false))

    private var cancellables = Set<AnyCancellable>()

    public init() {
        evaluateSubscriptionHistory()

        // Subscribe to real-time SK2 transaction updates
        Task.detached {
            for await _ in StoreKit.Transaction.updates {
                self.evaluateSubscriptionHistory()
            }
        }
    }

    private func evaluateSubscriptionHistory() {
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

            print("JOSH update subject \(found)")

            updateSubject.send(.init(hasAnySubscriptionHistory: found))
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@_spi(Internal)
public final class SubscriptionHistoryObserver: ObservableObject {

    public enum Status: Equatable {
        case unknown
        case hasHistory
        case noHistory
    }

    @Published public var status: Status = .unknown

    private var subscriptionTracker: Any?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            let tracker = SubscriptionHistoryTracker()
            self.subscriptionTracker = tracker
            bind(tracker)
        } else {
            // On older versions, we don't have access to SK2
            self.status = .unknown
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func bind(_ tracker: SubscriptionHistoryTracker) {
        tracker.updateSubject
            .map { $0.hasAnySubscriptionHistory ? Status.hasHistory : Status.noHistory }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.status = status
            }
            .store(in: &cancellables)
    }
}
