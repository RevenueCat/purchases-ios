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

/// Owns eligibility caching and request sharing. SK2 results are cached per subscription group;
/// SK1 and Simulated Store results remain cached per product. Product metadata comes from the
/// products manager, so offer availability is still evaluated for each product and billing plan.
class CachingTrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    private enum GroupEntry {
        case pending(Task<Bool, Never>)
        case cached(Bool)
    }

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
        var eligibilitiesByGroupID: [String: GroupEntry] = [:]

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

    private let checker: TrialOrIntroPriceEligibilityChecker
    private let state: Atomic<State> = .init(.init())

    init(checker: TrialOrIntroPriceEligibilityChecker) {
        self.checker = checker
    }

    func clearCache() {
        Logger.debug(Strings.eligibility.clearing_intro_eligibility_cache)

        self.state.modify {
            $0.cacheGeneration += 1
            $0.cachedEligibilities.removeAll(keepingCapacity: false)
            // A pending StoreKit check stays shared and caches its result when it finishes.
            $0.eligibilitiesByGroupID = $0.eligibilitiesByGroupID.filter {
                if case .pending = $0.value { return true }
                return false
            }
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

        if self.checker.usesSubscriptionGroupEligibility {
            // Cache the group answer only. Product metadata is already cached by the products manager.
            self.checker.checkEligibility(productIdentifiers: productIdentifiers,
                                          groupEligibilityChecker: self,
                                          completion: completion)
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

extension CachingTrialOrIntroPriceEligibilityChecker: SubscriptionGroupEligibilityChecker {

    func eligibility(
        for groupID: String,
        log: IntroEligibilityLog,
        check: @escaping @Sendable (String) async -> Bool
    ) async -> Bool {
        let (entry, reused) = self.state.modify { state -> (GroupEntry, Bool) in
            if let entry = state.eligibilitiesByGroupID[groupID] {
                return (entry, true)
            }

            let task = Task {
                let eligible = await log.eligibility(forSubscriptionGroup: groupID, check: check)
                // Write before returning to any waiter, so delayed waiters cannot restore a result
                // after a later invalidation or overwrite a newer check's answer.
                self.state.modify { $0.eligibilitiesByGroupID[groupID] = .cached(eligible) }
                return eligible
            }
            let entry = GroupEntry.pending(task)
            state.eligibilitiesByGroupID[groupID] = entry
            return (entry, false)
        }

        switch entry {
        case .cached(let eligible):
            log.reusedEligibility(forSubscriptionGroup: groupID, isPending: false)
            return eligible
        case .pending(let task):
            if reused {
                log.reusedEligibility(forSubscriptionGroup: groupID, isPending: true)
            }
            return await task.value
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
