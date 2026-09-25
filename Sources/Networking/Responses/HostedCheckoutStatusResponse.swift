//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutStatusResponse.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Foundation

/// What became of a checkout session, as the backend sees it.
struct HostedCheckoutStatusResponse: Equatable {

    let status: Status

    enum Status: Equatable {

        /// The session is under way. The caller keeps asking.
        ///
        /// Also stands for a status this version of the SDK does not know: a newer backend saying something
        /// new is likelier to be a step along the way than an outcome.
        case pending

        /// The purchase is on the customer's account.
        case succeeded

        /// The session ended without a purchase. `failure` is absent where the backend sends no detail.
        case failed(Failure?)

    }

    /// Why a session failed.
    struct Failure: Equatable {

        /// The backend's own code for the failure, which does not belong to ``BackendErrorCode``.
        let code: Int

        /// A wire-level name such as `payment_charge_failed`, meant for logs rather than for customers.
        let message: String?

        /// The customer already owns what the checkout would have sold them.
        var isAlreadyPurchased: Bool {
            return self.code == Self.alreadyPurchasedCode
        }

        private static let alreadyPurchasedCode = 5

    }

}

extension HostedCheckoutStatusResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case status
        case error
    }

    private enum RawStatus {
        static let started = "started"
        static let inProgress = "in_progress"
        static let succeeded = "succeeded"
        static let failed = "failed"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.status = Self.decodeStatus(try container.decode(String.self, forKey: .status), from: container)
    }

    private static func decodeStatus(
        _ rawStatus: String,
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> Status {
        switch rawStatus {
        case RawStatus.started, RawStatus.inProgress:
            return .pending
        case RawStatus.succeeded:
            return .succeeded
        case RawStatus.failed:
            return .failed(try? container.decodeIfPresent(Failure.self, forKey: .error))
        default:
            Logger.warn(Strings.hostedCheckout.unrecognized_status(rawStatus))
            return .pending
        }
    }

}

extension HostedCheckoutStatusResponse.Failure: Decodable {}

extension HostedCheckoutStatusResponse: HTTPResponseBody {}
