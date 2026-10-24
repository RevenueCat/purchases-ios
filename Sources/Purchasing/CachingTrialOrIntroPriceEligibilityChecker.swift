//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CachingTrialOrIntroPriceEligibilityChecker.swift
//
//  Created by Nacho Soto on 10/27/22.

import Foundation

// swiftlint:disable type_name

/// Owns per-product eligibility caching and request sharing, preserving synchronous cache hits.
/// Also invalidates the injected SK2 group cache used by the underlying checker.
class CachingTrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    private struct RequestKey: Hashable, Sendable {
        let productIdentifiers: Set<String>
        let cacheGeneration: Int
    }

    private enum Request {
        case complete([String: IntroEligibility])
        case pending(Task<[String: IntroEligibility], Never>, cached: [String: IntroEligibility], missing: Set<String>)

        var value: [String: IntroEligibility] {
            get async {
                switch self {
                case .complete(let result):
                    return result
                case let .pending(task, cached, missing):
                    return cached + (await task.value).filter { missing.contains($0.key) }
                }
            }
        }
    }

    private struct State {
        var cachedEligibilities: [String: IntroEligibility] = [:]
        var cacheGeneration = 0
        var inFlightRequests: [RequestKey: Task<[String: IntroEligibility], Never>] = [:]
    }

    private let checker: TrialOrIntroPriceEligibilityChecker
    private let state: Atomic<State> = .init(.init())

    init(checker: TrialOrIntroPriceEligibilityChecker) {
        self.checker = checker
    }

    func clearCache() {
        Logger.debug(Strings.eligibility.clearing_intro_eligibility_cache)

        self.state.modify {
            self.checker.clearCache()
            $0.cacheGeneration += 1
            $0.cachedEligibilities.removeAll(keepingCapacity: false)
            $0.inFlightRequests.removeAll(keepingCapacity: false)
        }
    }

}

extension CachingTrialOrIntroPriceEligibilityChecker {

    func checkEligibility(product: StoreProductType, completion: @escaping (IntroEligibilityStatus) -> Void) {
        self.checkEligibility(productIdentifiers: [product.id]) { eligibility in
            completion(eligibility[product.id]?.status ?? .unknown)
        }
    }

    func checkEligibility(
        productIdentifiers: Set<String>,
        completion: @escaping ReceiveIntroEligibilityBlock
    ) {
        let request = self.prepareRequest(productIdentifiers: productIdentifiers)
        if case .complete(let cached) = request {
            completion(cached)
        } else {
            _ = Task<Void, Never> {
                let result = await request.value
                self.checker.deliverEligibility(result, completion: completion)
            }
        }
    }

    func checkEligibility(productIdentifiers: Set<String>) async -> [String: IntroEligibility] {
        return await self.prepareRequest(productIdentifiers: productIdentifiers).value
    }

}

private extension CachingTrialOrIntroPriceEligibilityChecker {

    private func prepareRequest(productIdentifiers: Set<String>) -> Request {
        let (request, cachedProductIDs, joined) = self.state.modify { state -> (Request, Set<String>, Bool) in
            let cached = state.cachedEligibilities.filter { productIdentifiers.contains($0.key) }
            let cachedProductIDs = Set(cached.keys)
            let missingProducts = productIdentifiers.subtracting(cached.keys)
            guard !missingProducts.isEmpty else { return (.complete(cached), cachedProductIDs, false) }

            if let pending = state.inFlightRequests.first(where: {
                $0.key.productIdentifiers.isSuperset(of: missingProducts)
            }) {
                return (.pending(pending.value, cached: cached, missing: missingProducts), cachedProductIDs, true)
            }

            let key = RequestKey(productIdentifiers: missingProducts, cacheGeneration: state.cacheGeneration)
            // Keep an awaitable task at both cache layers so joining async callers can raise the work's priority.
            let task = Task {
                let result = await self.checker.checkEligibility(productIdentifiers: missingProducts)
                self.cache(result, for: key)
                return result
            }
            state.inFlightRequests[key] = task
            return (.pending(task, cached: cached, missing: missingProducts), cachedProductIDs, false)
        }
        if !cachedProductIDs.isEmpty {
            Logger.debug(Strings.eligibility.found_cached_eligibility_for_products(cachedProductIDs))
        }
        if joined {
            Logger.debug(Strings.eligibility.waiting_for_intro_eligibility(productIdentifiers))
        }
        return request
    }

    private func cache(_ result: [String: IntroEligibility], for key: RequestKey) {
        let productsToCache = result.filter { $0.value.shouldCache }
        let didCache = self.state.modify { state in
            guard state.cacheGeneration == key.cacheGeneration else { return false }
            state.cachedEligibilities += productsToCache
            state.inFlightRequests.removeValue(forKey: key)
            return true
        }
        if didCache {
            Logger.debug(Strings.eligibility.caching_intro_eligibility_for_products(Set(productsToCache.keys)))
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension CachingTrialOrIntroPriceEligibilityChecker: @unchecked Sendable {}

// MARK: - Private

private extension IntroEligibility {

    var shouldCache: Bool {
        switch self.status {
        case .noIntroOfferExists, .ineligible, .eligible: return true
        case .unknown: return false
        }
    }

}
