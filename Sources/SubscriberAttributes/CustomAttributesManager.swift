//
//  CustomAttributesManager.swift
//  
//
//  Created by Josh Holtz on 3/7/24.
//

import Foundation

class CustomAttributesManager {
    private let manualRateLimiter = RateLimiter(maxCalls: 5, period: 60)
    private let automaticRateLimiter = RateLimiter(maxCalls: 5, period: 60)
    private let automaticThrottler = Throttler(delayInSeconds: 2)

    let offeringsManager: OfferingsManager

    init(offeringsManager: OfferingsManager) {
        self.offeringsManager = offeringsManager
    }

    func syncAttributesAndOfferingsIfNeeded(
        appUserID: String,
        attribution: Attribution,
        subscriberAttributionsManager: SubscriberAttributesManager,
        completion: @escaping (Offerings?, PublicError?) -> Void
    ) {
        guard manualRateLimiter.shouldProceed() else {
            Logger.warn(
                Strings.identity.sync_attributes_and_offerings_rate_limit_reached(
                    maxCalls: manualRateLimiter.maxCalls,
                    period: Int(manualRateLimiter.period)
                )
            )
            self.getOfferings(appUserID: appUserID,
                              fetchPolicy: .default,
                              fetchBehavior: .cachedOrFetched,
                              completion: completion)
            return
        }

        self.syncSubscriberAttributes(
            appUserID: appUserID,
            attribution: attribution,
            completion: {
                self.getOfferings(appUserID: appUserID,
                                  fetchPolicy: .default,
                                  fetchBehavior: .fetchCurrent(reason: .manualSyncCustomAttributes),
                                  completion: completion)
        })

    }

    func syncCustomAttributesAndOfferingsIfNeeded(
        appUserID: String,
        attribution: Attribution,
        subscriberAttributionsManager: SubscriberAttributesManager
    ) {
        let hasUnsyncedCustomAttributes = self.hasUnsyncedCustomAttributes(
            appUserID: appUserID,
            attribution: attribution,
            subscriberAttributionsManager: subscriberAttributionsManager
        )

        if hasUnsyncedCustomAttributes {
            guard automaticRateLimiter.shouldProceed() else {
                Logger.warn(
                    Strings.identity.sync_custom_attributes_rate_limit_reached(
                        maxCalls: manualRateLimiter.maxCalls,
                        period: Int(manualRateLimiter.period)
                    )
                )
                return
            }

            automaticThrottler.throttle {
                self.syncSubscriberAttributes(
                    appUserID: appUserID,
                    attribution: attribution,
                    completion: {
                        self.getOfferings(appUserID: appUserID,
                                          fetchPolicy: .default,
                                          fetchBehavior: .fetchCurrent(reason: .automaticSyncCustomAttributes),
                                          completion: { _, _ in })
                })
            }
        }
    }

}

private class Throttler {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delayInSeconds: Double

    init(delayInSeconds: Double, queue: DispatchQueue = DispatchQueue.main) {
        self.delayInSeconds = delayInSeconds
        self.queue = queue
    }

    func throttle(_ block: @escaping () -> Void) {
        workItem?.cancel()

        let task = DispatchWorkItem { block() }
        self.workItem = task

        queue.asyncAfter(deadline: .now() + delayInSeconds, execute: task)
    }
}

private extension CustomAttributesManager {
    func hasUnsyncedCustomAttributes(
        appUserID: String,
        attribution: Attribution,
        subscriberAttributionsManager: SubscriberAttributesManager
    ) -> Bool {
        guard let customAttributes = self.offeringsManager.cachedOfferings?.targeting?.customAttributes else {
            return false
        }

        let unsyncedKeys = attribution.unsyncedAttributesByKey(appUserID: appUserID).keys
        guard !unsyncedKeys.isEmpty else {
            return false
        }

        let saltedAndHashedKeys = Set(unsyncedKeys.map { key in
            return "\(customAttributes.salt)\(key)".asData.hashString
        })

        let intersect = saltedAndHashedKeys.intersection(Set(customAttributes.keys))

        return !intersect.isEmpty
    }

    func getOfferings(
        appUserID: String,
        fetchPolicy: OfferingsManager.FetchPolicy,
        fetchBehavior: OfferingsManager.FetchBehavior,
        completion: @escaping (Offerings?, PublicError?) -> Void
    ) {
        self.offeringsManager.offerings(appUserID: appUserID,
                                        fetchPolicy: fetchPolicy,
                                        fetchBehavior: fetchBehavior) { @Sendable result in
            completion(result.value, result.error?.asPublicError)
        }
    }

    @discardableResult
    func syncSubscriberAttributes(
        appUserID: String,
        attribution: Attribution,
        syncedAttribute: (@Sendable (PublicError?) -> Void)? = nil,
        completion: (@Sendable () -> Void)? = nil
    ) -> Int {
        return attribution.syncAttributesForAllUsers(
            currentAppUserID: appUserID,
            syncedAttribute: { @Sendable in syncedAttribute?($0?.asPublicError) },
            completion: completion
        )
    }
}
