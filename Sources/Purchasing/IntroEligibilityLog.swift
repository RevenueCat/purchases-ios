//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

/// Correlates the product lookup and concurrent subscription-group checks for one eligibility request.
struct IntroEligibilityLog: Sendable {

    private let requestID = UUID().uuidString
    private let clock: ClockType
    private let startTime: DispatchTime

    init(clock: ClockType = Clock.default) {
        self.clock = clock
        self.startTime = clock.currentTime
    }

    func products<Product: StoreProductType & Hashable>(
        identifiers: Set<String>,
        fetch: (Set<String>) async throws -> Set<Product>
    ) async rethrows -> Set<Product> {
        let startTime = self.clock.currentTime
        Logger.debug(Strings.eligibility.product_lookup_started(requestID: self.requestID, identifiers: identifiers))
        do {
            let products = try await fetch(identifiers)
            Logger.debug(Strings.eligibility.product_lookup_finished(
                requestID: self.requestID,
                identifiers: Set(products.map(\.id)),
                missingIdentifiers: identifiers.subtracting(products.map(\.id)),
                duration: self.clock.durationSince(startTime)
            ))
            return products
        } catch {
            Logger.debug(Strings.eligibility.product_lookup_failed(
                requestID: self.requestID, error: error, duration: self.clock.durationSince(startTime)
            ))
            throw error
        }
    }

    func eligibility(forSubscriptionGroup groupID: String, check: @Sendable (String) async -> Bool) async -> Bool {
        let startTime = self.clock.currentTime
        Logger.debug(Strings.eligibility.subscription_group_check_started(requestID: self.requestID, groupID: groupID))
        let eligible = await TimingUtil.measureAndLogIfTooSlow(
            threshold: .introEligibility,
            message: Strings.eligibility.sk2_intro_eligibility_too_slow.description
        ) {
            await check(groupID)
        }
        Logger.debug(Strings.eligibility.subscription_group_check_finished(
            requestID: self.requestID,
            groupID: groupID,
            eligible: eligible,
            duration: self.clock.durationSince(startTime)
        ))
        return eligible
    }

    func finished(_ result: [String: IntroEligibility]) {
        Logger.debug(Strings.eligibility.check_finished(
            requestID: self.requestID, result: result, duration: self.clock.durationSince(self.startTime)
        ))
    }

}
