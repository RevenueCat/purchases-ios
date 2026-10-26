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

/// `TrialOrIntroPriceEligibilityCheckerType` decorator that adds caching behavior on each request.
class CachingTrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    private struct RequestKey: Hashable, Sendable {
        let productIdentifiers: Set<String>
        let cacheGeneration: Int
    }

    private enum RequestAction {
        case complete([String: IntroEligibility])
        case wait
        case start(RequestKey)
    }

    private struct State {
        var cachedEligibilities: [String: IntroEligibility] = [:]
        var cacheGeneration = 0
        var inFlightRequests: [RequestKey: [ReceiveIntroEligibilityBlock]] = [:]

        mutating func prepareRequest(
            productIdentifiers: Set<String>,
            completion: @escaping ReceiveIntroEligibilityBlock
        ) -> (action: RequestAction, cachedProductIdentifiers: Set<String>) {
            let cached = self.cachedEligibilities.filter { productIdentifiers.contains($0.key) }
            let cachedProductIdentifiers = Set(cached.keys)
            let missingProducts = productIdentifiers.subtracting(cached.keys)

            guard !missingProducts.isEmpty else {
                return (.complete(cached), cachedProductIdentifiers)
            }

            let requestKey = RequestKey(
                productIdentifiers: missingProducts,
                cacheGeneration: self.cacheGeneration
            )
            let containingRequestKey = self.inFlightRequests.keys.first { inFlightRequestKey in
                inFlightRequestKey.cacheGeneration == requestKey.cacheGeneration
                    && inFlightRequestKey.productIdentifiers.isSuperset(of: requestKey.productIdentifiers)
            }
            let key = containingRequestKey ?? requestKey
            self.inFlightRequests[key, default: []].append { fetched in
                let requestedProducts = fetched.filter { requestKey.productIdentifiers.contains($0.key) }
                completion(cached + requestedProducts)
            }

            let action: RequestAction = containingRequestKey == nil ? .start(requestKey) : .wait
            return (action, cachedProductIdentifiers)
        }
    }

    private let checker: TrialOrIntroPriceEligibilityCheckerType
    private let state: Atomic<State> = .init(.init())

    /// Creates a `CachingTrialOrIntroPriceEligibilityChecker` wrapping the underlying checker,
    /// or returns `checker` if it already is this type.
    static func create(
        with checker: TrialOrIntroPriceEligibilityCheckerType
    ) -> CachingTrialOrIntroPriceEligibilityChecker {
        if let checker = checker as? Self {
            return checker
        } else {
            return CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        }
    }

    init(checker: TrialOrIntroPriceEligibilityCheckerType) {
        self.checker = checker
    }

    func clearCache() {
        Logger.debug(Strings.eligibility.clearing_intro_eligibility_cache)

        self.state.modify {
            $0.cacheGeneration += 1
            $0.cachedEligibilities.removeAll(keepingCapacity: false)
        }
    }

}

extension CachingTrialOrIntroPriceEligibilityChecker {

    func checkEligibility(
        productIdentifiers: Set<String>,
        completion: @escaping ReceiveIntroEligibilityBlock
    ) {
        guard !productIdentifiers.isEmpty else {
            completion([:])
            return
        }

        let (action, cachedProductIdentifiers) = self.state.modify {
            $0.prepareRequest(productIdentifiers: productIdentifiers, completion: completion)
        }

        if !cachedProductIdentifiers.isEmpty {
            Logger.debug(Strings.eligibility.found_cached_eligibility_for_products(cachedProductIdentifiers))
        }

        switch action {
        case .complete(let cached):
            completion(cached)
        case .wait:
            Logger.debug(Strings.eligibility.waiting_for_intro_eligibility(productIdentifiers))
            return
        case .start(let requestKey):
            self.checker.checkEligibility(
                productIdentifiers: requestKey.productIdentifiers,
                completion: { result in
                    let productsToCache = result.filter { $0.value.shouldCache }
                    let (completions, didCache) = self.state.modify { state in
                        let didCache = state.cacheGeneration == requestKey.cacheGeneration
                        if didCache {
                            state.cachedEligibilities += productsToCache
                        }
                        let completions = state.inFlightRequests.removeValue(forKey: requestKey) ?? []
                        return (completions, didCache)
                    }

                    if didCache {
                        Logger.debug(
                            Strings.eligibility.caching_intro_eligibility_for_products(Set(productsToCache.keys))
                        )
                    }

                    Task { @MainActor in
                        completions.forEach { $0(result) }
                    }
                }
            )
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
