//
//  Outcome.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Terminal outcome of an SSV polling session: returned by `Poller.run` and forwarded to
    /// the dispatcher's outcome handler.
    ///
    /// Only two cases by design — there is nothing the consumer can do differently between
    /// "backend rejected", "we ran out of attempts on `pending`", and "every attempt threw":
    /// the ad has already been shown and the verdict is final. Operator-relevant detail about
    /// *why* `.failed` happened lives in logs at the point of detection inside the Poller, not
    /// on this surface.
    enum Outcome: Equatable, @unchecked Sendable {
        case verified(VerifiedReward)

        /// The SSV pipeline did not produce a verified reward. Reasons folded into this case:
        /// an explicit backend `failed` verdict, exhausted attempt budget on `pending`/`unknown`,
        /// or exhausted attempt budget after repeated transient errors.
        case failed
    }
}

#endif
