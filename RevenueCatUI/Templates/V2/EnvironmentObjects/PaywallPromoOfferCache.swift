//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPromoOfferCacheV2.swift
//
//  Created by Josh Holtz on 7/28/25.

import Combine
import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

/// Presentation-scoped cache shared by a paywall's workflow pages and exit offer.
/// A separate paywall presentation intentionally starts with a new cache.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal final class PaywallPromoOfferCache: ObservableObject {

    typealias ProductID = String
    typealias PackageInfo = (package: Package, promotionalOfferProductCode: String?)
    typealias OfferFetcher = @MainActor (StoreProductDiscount, StoreProduct) async throws -> PromotionalOffer

    private struct CacheKey: Hashable {
        let appUserID: String
        let productID: ProductID
        let promotionalOfferProductCode: String
    }

    private struct CacheContext: Hashable {
        let appUserID: String
        let purchasesInstance: ObjectIdentifier?
    }

    private struct InFlightKey: Hashable {
        let cacheKey: CacheKey
        let context: CacheContext
    }

    private struct Request {
        let key: CacheKey
        let discount: StoreProductDiscount
        let product: StoreProduct
    }

    enum Status: Equatable {
        case unknown
        case ineligible
        case signedEligible(PromotionalOffer)
    }

    @Published
    private var cache: [CacheKey: Status] = [:]
    @Published
    private var hasAnySubscriptionHistory: Bool = false
    private var cancellable: AnyCancellable?
    private var cachedContext: CacheContext?
    private var promotionalOfferProductCodesByProductID: [ProductID: String] = [:]
    private var inFlightTasks: [InFlightKey: Task<Status?, Never>] = [:]

    /// When true, eligibility is fabricated locally (dummy signed offers) instead of fetched from the
    /// backend, so paywall previews/mocks can show promo components and pricing without a real
    /// subscriber or a backend-signed offer.
    private let simulateEligible: Bool
    private let requestTimeout: TimeInterval
    private let signatureValidityDuration: TimeInterval
    private let contextProvider: @MainActor () -> CacheContext
    private let offerFetcher: OfferFetcher
    private let dateProvider: @MainActor () -> Date

    private static let defaultRequestTimeout: TimeInterval = 5
    // Apple promotional-offer signatures are valid for 24 hours from their timestamp.
    private static let defaultSignatureValidityDuration: TimeInterval = 24 * 60 * 60

    // MARK: - Init

    init(subscriptionHistoryTracker: SubscriptionHistoryTracker?, simulateEligible: Bool = false) {
        self.simulateEligible = simulateEligible
        self.requestTimeout = Self.defaultRequestTimeout
        self.signatureValidityDuration = Self.defaultSignatureValidityDuration
        self.contextProvider = {
            guard Purchases.isConfigured else {
                return CacheContext(appUserID: "", purchasesInstance: nil)
            }

            return CacheContext(
                appUserID: Purchases.shared.appUserID,
                purchasesInstance: ObjectIdentifier(Purchases.shared)
            )
        }
        self.offerFetcher = { discount, product in
            return try await Purchases.shared.promotionalOffer(
                forProductDiscount: discount,
                product: product
            )
        }
        self.dateProvider = Date.init

        // Simulate mode passes no tracker: it only ever produces `.signedEligible`/absent entries,
        // which never consult `hasAnySubscriptionHistory`, so we skip the tracker's StoreKit work.
        guard let subscriptionHistoryTracker else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.cancellable = await subscriptionHistoryTracker.status
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    self?.hasAnySubscriptionHistory = status == .hasHistory
                }
        }
    }

    /// Dependency-injecting initializer used to exercise request coalescing, expiration, and timeout behavior.
    init(
        subscriptionHistoryTracker: SubscriptionHistoryTracker? = nil,
        requestTimeout: TimeInterval,
        signatureValidityDuration: TimeInterval = 24 * 60 * 60,
        appUserIDProvider: @escaping @MainActor () -> String,
        purchasesInstanceProvider: @escaping @MainActor () -> ObjectIdentifier?,
        dateProvider: @escaping @MainActor () -> Date = Date.init,
        offerFetcher: @escaping OfferFetcher
    ) {
        self.simulateEligible = false
        self.requestTimeout = requestTimeout
        self.signatureValidityDuration = signatureValidityDuration
        self.contextProvider = {
            CacheContext(
                appUserID: appUserIDProvider(),
                purchasesInstance: purchasesInstanceProvider()
            )
        }
        self.offerFetcher = offerFetcher
        self.dateProvider = dateProvider

        guard let subscriptionHistoryTracker else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.cancellable = await subscriptionHistoryTracker.status
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    self?.hasAnySubscriptionHistory = status == .hasHistory
                }
        }
    }

    /// Builds a cache that fabricates dummy signed promo offers for matching packages, for paywall
    /// previews/mocks. No network or real subscription required. Seeding happens during the view's
    /// eligibility `.task`, so it does not run in Xcode Previews / Emerge snapshots (where that task
    /// is skipped); it does run in a normally-launched preview app.
    convenience init(simulateEligible: Bool) {
        self.init(subscriptionHistoryTracker: nil, simulateEligible: simulateEligible)
    }

    /// The cache a preview needs for `simulateEligible`, or `nil` to leave the real one in place.
    /// Single mapping site, so an initializer that forwards the flag cannot forget to build it.
    static func simulated(if simulateEligible: Bool) -> PaywallPromoOfferCache? {
        return simulateEligible ? PaywallPromoOfferCache(simulateEligible: true) : nil
    }

    // MARK: - Public API

    func computeEligibility(for packageInfos: [PackageInfo]) async {
        while !Task.isCancelled {
            if await self.checkSignedEligibility(packageInfos: packageInfos) {
                return
            }
        }
    }

    func isMostLikelyEligible(for package: Package?) -> Bool {
        guard let package else { return false }

        let status = self.status(for: package) ?? .ineligible
        switch status {
        case .unknown, .signedEligible:
            return true
        case .ineligible:
            return hasAnySubscriptionHistory
        }
    }

    func get(for package: Package?) -> PromotionalOffer? {
        guard let package else { return nil }

        if case .signedEligible(let promoOffer) = self.status(for: package) {
            return promoOffer
        }

        return nil
    }

    /// The signed offer to forward to a real purchase. Returns `nil` in simulate mode so a fabricated
    /// offer (sentinel signing data) never reaches StoreKit; display paths still use `get(for:)`. A
    /// valid cached signature is returned immediately. Missing or expired signatures get one bounded,
    /// retryable refresh before the purchase proceeds without the promo.
    func purchasableOffer(for package: Package?) async -> PromotionalOffer? {
        guard !self.simulateEligible, let package else { return nil }

        if let offer = self.get(for: package) {
            return offer
        }

        let productID = package.storeProduct.productIdentifier
        guard let productCode = self.promotionalOfferProductCodesByProductID[productID] else {
            return nil
        }

        await self.computeEligibility(for: [(package, productCode)])
        return self.get(for: package)
    }

    // MARK: - Internal Logic

    /// Returns whether the results were computed for the context that is still current.
    private func checkSignedEligibility(packageInfos: [PackageInfo]) async -> Bool {
        let context = self.contextProvider()
        let requestsByKey = self.requests(packageInfos: packageInfos, context: context)

        // Build up results in a local dictionary first, then assign all at once.
        // This ensures a single atomic update to the @Published property,
        // which reliably triggers objectWillChange and view updates.
        var newCacheEntries: [CacheKey: Status] = [:]
        var tasks: [(CacheKey, InFlightKey, Task<Status?, Never>)] = []

        // Start every unique cold check before awaiting any of them. Existing in-flight work is shared
        // by all pages using this presentation-scoped cache.
        for request in requestsByKey.values {
            if let cachedStatus = self.cachedStatus(for: request.key, context: context) {
                newCacheEntries[request.key] = cachedStatus
                continue
            }

            let inFlightKey = InFlightKey(cacheKey: request.key, context: context)
            let task = self.task(
                for: inFlightKey,
                discount: request.discount,
                product: request.product
            )
            tasks.append((request.key, inFlightKey, task))
        }

        for (key, inFlightKey, task) in tasks {
            if let status = await task.value {
                newCacheEntries[key] = status
            }
            self.inFlightTasks[inFlightKey] = nil
        }

        // An identity or Purchases configuration change while requests were running makes every result stale.
        guard self.contextProvider() == context else { return false }

        var updatedCache = self.cachedContext == context ? self.cache : [:]
        for (key, value) in newCacheEntries {
            updatedCache[key] = value
        }

        // A failed or timed-out request deliberately contributes no entry, so a later page or purchase can retry.
        if self.cachedContext != context || updatedCache != self.cache {
            self.cachedContext = context
            self.cache = updatedCache
        }

        return true
    }

    private func requests(packageInfos: [PackageInfo], context: CacheContext) -> [CacheKey: Request] {
        var requestsByKey: [CacheKey: Request] = [:]
        var routedProductIDs: Set<ProductID> = []

        for packageInfo in packageInfos {
            let storeProduct = packageInfo.package.storeProduct
            let productID = storeProduct.productIdentifier

            // A workflow page can configure a different App Store promotional offer for the same
            // product. Route reads and purchases to this computation's first placement while retaining
            // separately keyed cached signatures for offers used by other pages.
            if routedProductIDs.insert(productID).inserted {
                self.promotionalOfferProductCodesByProductID[productID] =
                    packageInfo.promotionalOfferProductCode
            }

            guard let productCode = packageInfo.promotionalOfferProductCode else { continue }
            guard let discount = storeProduct.discounts.first(where: { $0.offerIdentifier == productCode }) else {
                continue
            }

            let key = CacheKey(
                appUserID: context.appUserID,
                productID: productID,
                promotionalOfferProductCode: productCode
            )
            if requestsByKey[key] == nil {
                requestsByKey[key] = Request(key: key, discount: discount, product: storeProduct)
            }
        }

        return requestsByKey
    }

    private func task(
        for key: InFlightKey,
        discount: StoreProductDiscount,
        product: StoreProduct
    ) -> Task<Status?, Never> {
        if let task = self.inFlightTasks[key] {
            return task
        }

        let task: Task<Status?, Never> = Task { @MainActor [offerFetcher, requestTimeout, simulateEligible] in
            if simulateEligible {
                return Status.signedEligible(Self.makeSimulatedOffer(for: discount))
            }

            return await Self.fetchStatus(
                discount: discount,
                product: product,
                timeout: requestTimeout,
                offerFetcher: offerFetcher
            )
        }
        self.inFlightTasks[key] = task
        return task
    }

    private static func fetchStatus(
        discount: StoreProductDiscount,
        product: StoreProduct,
        timeout: TimeInterval,
        offerFetcher: @escaping OfferFetcher
    ) async -> Status? {
        return await withUnsafeContinuation { (continuation: UnsafeContinuation<Status?, Never>) in
            let completion = PromoOfferRequestCompletion(continuation)

            completion.timeoutTask = Task { @MainActor in
                let nanoseconds = UInt64(max(0, timeout) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
                guard !Task.isCancelled else { return }
                completion.resolve(nil)
            }

            // This is intentionally unstructured: a signing call that ignores cancellation must not keep
            // the paywall's structured task scope alive after the timeout wins.
            Task { @MainActor in
                do {
                    let offer = try await offerFetcher(discount, product)
                    completion.resolve(.signedEligible(offer))
                } catch ErrorCode.ineligibleError {
                    completion.resolve(.ineligible)
                } catch {
                    // Network and other transient failures are not cached.
                    completion.resolve(nil)
                }
            }
        }
    }

    private func status(for package: Package) -> Status? {
        let productID = package.storeProduct.productIdentifier
        guard let productCode = self.promotionalOfferProductCodesByProductID[productID] else {
            return nil
        }

        let context = self.contextProvider()
        let key = CacheKey(
            appUserID: context.appUserID,
            productID: productID,
            promotionalOfferProductCode: productCode
        )
        return self.cachedStatus(for: key, context: context)
    }

    private func cachedStatus(for key: CacheKey, context: CacheContext) -> Status? {
        guard self.cachedContext == context, let status = self.cache[key] else {
            return nil
        }

        guard case .signedEligible(let offer) = status else {
            return status
        }

        guard !self.simulateEligible else {
            return status
        }

        let signatureDate = Date(timeIntervalSince1970: TimeInterval(offer.signedData.timestamp) / 1_000)
        let age = self.dateProvider().timeIntervalSince(signatureDate)
        guard age >= 0, age < self.signatureValidityDuration else {
            return nil
        }

        return status
    }

    /// Fabricates a dummy signed offer for previews. The signing values are sentinels: this offer is
    /// only used to drive promo display/pricing in a mock, never sent to the backend.
    private static func makeSimulatedOffer(for discount: StoreProductDiscount) -> PromotionalOffer {
        return discount.promotionalOffer(
            withSignedDataIdentifier: "preview",
            keyIdentifier: "preview",
            nonce: UUID(),
            signature: "preview",
            timestamp: 0
        )
    }
}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class PromoOfferRequestCompletion {

    var timeoutTask: Task<Void, Never>?
    private var continuation: UnsafeContinuation<PaywallPromoOfferCache.Status?, Never>?

    init(_ continuation: UnsafeContinuation<PaywallPromoOfferCache.Status?, Never>) {
        self.continuation = continuation
    }

    func resolve(_ status: PaywallPromoOfferCache.Status?) {
        guard let continuation = self.continuation else { return }

        self.continuation = nil
        self.timeoutTask?.cancel()
        continuation.resume(returning: status)
    }

}
