//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+AdMob.swift
//

import Foundation

// MARK: - AdMob SSV (Internal SPI)

extension Purchases {

    /// Polls the backend once for AdMob SSV verification status using `client_transaction_id`.
    ///
    /// Internal API for RC ad adapters.
    ///
    /// Cancelling the calling `Task` does not cancel the in-flight HTTP request.
    @_spi(Internal) public func pollAdMobSSVStatus(
        clientTransactionID: String
    ) async throws -> AdMobSSVPollStatus {
        let response = try await Async.call { completion in
            self.backend.adsAPI.getAdMobSSVStatus(
                appUserID: self.appUserID,
                clientTransactionID: clientTransactionID
            ) { result in
                completion(result.mapError(\.asPublicError))
            }
        }

        switch response.status {
        case .validated:
            return .validated
        case .pending:
            return .pending
        case .failed:
            return .failed
        case .unknown:
            // Defensive: treat unrecognized future statuses as still-pending so the
            // adapter keeps polling rather than firing a false terminal outcome.
            return .pending
        }
    }

}
