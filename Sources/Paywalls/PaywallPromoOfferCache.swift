//
//  PaywallPromoOfferCache.swift
//  RevenueCat
//
//  Created by Josh Holtz on 6/17/25.
//
// swiftlint:disable missing_docs

import Combine
import StoreKit

@available(iOS 15.0, *)
public actor SubscriptionHistoryTracker {

    public struct Update: Equatable, Sendable {
        public let hasAnySubscriptionHistory: Bool
    }

    private var continuation: AsyncStream<Update>.Continuation?
    private(set) var updates: AsyncStream<Update>!

    public init() {
        Task { await self.configureStream() }
        Task { await self.evaluateSubscriptionHistory() }

        Task.detached {
            for await _ in StoreKit.Transaction.updates {
                await self.evaluateSubscriptionHistory()
            }
        }
    }

    private func configureStream() {
        let (stream, continuation) = Self.makeStream()
        self.updates = stream
        self.continuation = continuation
    }

    private static func makeStream() -> (AsyncStream<Update>, AsyncStream<Update>.Continuation) {
        var continuation: AsyncStream<Update>.Continuation!
        let stream = AsyncStream<Update> { cont in
            continuation = cont
        }
        return (stream, continuation)
    }

    private func evaluateSubscriptionHistory() async {
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

        continuation?.yield(Update(hasAnySubscriptionHistory: found))
    }
}

@_spi(Internal) public protocol PaywallPromoOfferCacheType: Sendable {

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public actor PaywallPromoOfferCache: ObservableObject, PaywallPromoOfferCacheType {

    @_spi(Internal) public var hasAnySubscriptionHistory: Bool = false

    private let subscriptionTracker: SubscriptionHistoryTracker
    private var listenTask: Task<Void, Never>?

    // MARK: - Init

    @_spi(Internal) public init() {
        self.subscriptionTracker = SubscriptionHistoryTracker()
        Task { await self.configure() }
    }

    deinit {
        listenTask?.cancel()
    }

    private func configure() {
        self.listenTask = Task {
            await self.listenToSubscriptionUpdates()
        }
    }

    // MARK: - Subscription updates

    private func listenToSubscriptionUpdates() async {
        for await update in await subscriptionTracker.updates {
            self.hasAnySubscriptionHistory = update.hasAnySubscriptionHistory
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public final class PaywallPromoOfferCacheV2: ObservableObject {

    typealias ProductID = String
    @_spi(Internal) public typealias PackageInfo = (package: Package, promotionalOfferProductCode: String?)

    public enum Status: Equatable {
        case unknown
        case ineligible
        case signedEligible(PromotionalOffer)
    }

    private var cache: [ProductID: Status] = [:]
    private var hasAnySubscriptionHistory: Bool = false

    // MARK: - Init

    @_spi(Internal) public init(hasAnySubscriptionHistory: Bool = false) {
        self.hasAnySubscriptionHistory = hasAnySubscriptionHistory
    }

    // MARK: - Public API

    @_spi(Internal) public func computeEligibility(for packageInfos: [PackageInfo]) async {
        await self.checkSignedEligibility(packageInfos: packageInfos)
    }

    @_spi(Internal) public func isMostLikelyEligible(for package: Package?) -> Bool {
        guard let package else { return false }

        let status = cache[package.storeProduct.productIdentifier] ?? .ineligible
        switch status {
        case .unknown, .signedEligible:
            return true
        case .ineligible:
            return hasAnySubscriptionHistory
        }
    }

    @_spi(Internal) public func get(for package: Package?) -> PromotionalOffer? {
        guard let package else { return nil }

        if case .signedEligible(let promoOffer) = cache[package.storeProduct.productIdentifier] {
            return promoOffer
        }

        return nil
    }

    // MARK: - Internal Logic

    private func checkSignedEligibility(packageInfos: [PackageInfo]) async {
        for packageInfo in packageInfos {
            let storeProduct = packageInfo.package.storeProduct
            if let productCode = packageInfo.promotionalOfferProductCode,
               let discount = storeProduct.discounts.first(where: { $0.offerIdentifier == productCode }) {

                do {
                    let promoOffer = try await Purchases.shared.promotionalOffer(
                        forProductDiscount: discount,
                        product: storeProduct
                    )
                    cache[storeProduct.productIdentifier] = .signedEligible(promoOffer)
                } catch {
                    cache[storeProduct.productIdentifier] = .ineligible
                }
            }
        }
    }
}
