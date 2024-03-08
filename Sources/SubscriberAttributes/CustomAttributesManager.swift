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
            self.getOfferings(appUserID: appUserID, fetchPolicy: .default, completion: completion)
            return
        }

        self.syncSubscriberAttributes(
            appUserID: appUserID,
            attribution: attribution,
            completion: {
            self.getOfferings(appUserID: appUserID, fetchPolicy: .default, fetchCurrent: true, completion: completion)
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

            self.syncAttributesAndOfferingsIfNeeded(
                appUserID: appUserID,
                attribution: attribution,
                subscriberAttributionsManager: subscriberAttributionsManager) { _, _ in

                }
        }
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
        fetchCurrent: Bool = false,
        completion: @escaping (Offerings?, PublicError?) -> Void
    ) {
        self.offeringsManager.offerings(appUserID: appUserID,
                                        fetchPolicy: fetchPolicy,
                                        fetchCurrent: fetchCurrent) { @Sendable result in
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
