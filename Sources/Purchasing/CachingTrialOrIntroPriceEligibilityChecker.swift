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
        let productIdentifier: String
        let cacheGeneration: Int
    }

    private struct UncacheableEligibilityError: Error {
        let eligibility: IntroEligibility?
    }

    private let checker: TrialOrIntroPriceEligibilityCheckerType

    private let cache: Atomic<[String: IntroEligibility]> = .init([:])

    // This acts as a synchronous cache invalidation trigger to prevent a possible race condition
    // with actor cache clearing from a non-isolated context
    private let cacheGeneration: Atomic<Int> = .init(0)
    private let deferredRequests = KeyedDeferredValueStore<RequestKey, IntroEligibility>()

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

        self.cacheGeneration.modify {
            $0 += 1
        }
        Task(priority: .userInitiated) {
            await self.deferredRequests.clear()
        }
        self.cache.value.removeAll(keepingCapacity: false)
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

        let uniqueProductIdentifiers = Set(productIdentifiers)

        let cached = self.cache.value.filter { uniqueProductIdentifiers.contains($0.key) }

        if !cached.isEmpty {
            Logger.debug(Strings.eligibility.found_cached_eligibility_for_products(Set(cached.keys)))
        }

        let missingProducts = uniqueProductIdentifiers.subtracting(cached.keys)

        if missingProducts.isEmpty {
            completion(cached)
        } else {
            let cacheGeneration = self.cacheGeneration.value
            let requestKeys = Set(missingProducts.map {
                RequestKey(productIdentifier: $0, cacheGeneration: cacheGeneration)
            })

            Task {
                let tasks = await self.tasks(for: requestKeys, cacheGeneration: cacheGeneration)

                var result = cached
                for (requestKey, task) in tasks {
                    do {
                        result[requestKey.productIdentifier] = try await task.value
                    } catch let error as UncacheableEligibilityError {
                        result[requestKey.productIdentifier] = error.eligibility
                    }
                }

                await MainActor.run {
                    completion(result)
                }
            }
        }
    }

    private func tasks(
        for requestKeys: Set<RequestKey>,
        cacheGeneration: Int
    ) async -> [RequestKey: AnyTask<IntroEligibility>] {
        var tasks: [RequestKey: AnyTask<IntroEligibility>] = [:]

        for requestKey in requestKeys {
            tasks[requestKey] = await self.deferredRequests.getOrPut(
                Task {
                    return try await self.checkEligibility(
                        for: requestKey,
                        cacheGeneration: cacheGeneration
                    )
                },
                forKey: requestKey
            )
        }

        return tasks
    }

    private func checkEligibility(
        for requestKey: RequestKey,
        cacheGeneration: Int
    ) async throws -> IntroEligibility {
        let productIdentifier = requestKey.productIdentifier
        let result = await Async.call { completion in
            self.checker.checkEligibility(
                productIdentifiers: [productIdentifier],
                completion: completion
            )
        }

        guard let eligibility = result[productIdentifier],
              eligibility.shouldCache,
              self.cacheGeneration.value == cacheGeneration else {
            throw UncacheableEligibilityError(eligibility: result[productIdentifier])
        }

        Logger.debug(Strings.eligibility.caching_intro_eligibility_for_products([productIdentifier]))
        self.cache.modify { $0[productIdentifier] = eligibility }

        return eligibility
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
