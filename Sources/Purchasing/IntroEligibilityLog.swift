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

/// Gives intro eligibility logs consistent timing, results, and request context.
/// Each instance uses one request ID for product lookup and concurrent subscription-group checks,
/// so related messages can be matched even when logs from different requests are interleaved.
/// Separate stage timings show time spent retrieving products and checking eligibility with StoreKit.
/// An injected monotonic clock keeps elapsed times independent of changes to the device's date.
struct IntroEligibilityLog: Sendable {

    private let requestID = UUID().uuidString
    private let clock: ClockType
    private let startTime: DispatchTime

    init(clock: ClockType = Clock.default) {
        self.clock = clock
        self.startTime = clock.currentTime
    }

    /// Measures the wait between scheduling the completion on the main actor and beginning its delivery.
    /// This reports callback scheduling delay separately from the completed eligibility work.
    /// Invoke the returned logger inside the dispatched block, immediately before calling the completion.
    /// The duration excludes execution of the completion and subsequent UI rendering.
    static func deliveryLogger(clock: ClockType) -> @Sendable ([String: IntroEligibility]) -> Void {
        let startTime = clock.currentTime
        return { result in
            Logger.debug(Strings.eligibility.delivering_intro_eligibility(
                result: result, duration: clock.durationSince(startTime)
            ))
        }
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
            threshold: Configuration.TimingThreshold.introEligibility.rawValue,
            message: Strings.eligibility.sk2_intro_eligibility_too_slow.description,
            clock: self.clock
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
