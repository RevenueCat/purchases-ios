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
    /// "backend rejected", "we ran out of attempts on `pending`", and "the request kept
    /// failing": the ad has already been shown and the verdict is final.
    enum Outcome: @unchecked Sendable {
        case verified(VerifiedReward)

        /// The SSV pipeline did not produce a verified reward. Reasons folded into this case:
        /// an explicit backend `failed` verdict, exhausted attempt budget on `pending`/`unknown`,
        /// exhausted attempt budget after repeated transient errors, a terminal `ErrorCode` from
        /// the SPI (e.g. signature verification failed), or the dispatcher's safety net for an
        /// unexpected throw.
        case failed
    }
}

#endif
