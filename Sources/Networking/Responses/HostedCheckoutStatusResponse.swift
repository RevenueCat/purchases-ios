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
        /// Also stands for a status this version of the SDK does not know.
        case pending

        /// The purchase is on the customer's account. `purchase` is absent where the backend sends no detail.
        case succeeded(Purchase?)

        /// The session ended without a purchase. `failure` is absent where the backend sends no detail.
        case failed(Failure?)

    }

    /// The purchase a session made, as it appears on the customer's account.
    struct Purchase: Equatable {

        let storeTransactionIdentifier: String
        let productIdentifier: String
        let purchaseDate: Date
        let isSandbox: Bool

    }

    /// Why a session failed.
    struct Failure: Equatable {

        /// The backend's code for why the purchase failed. These codes are shared with the web purchase flow
        /// in purchases-js.
        let code: Int

        /// A wire-level name such as `payment_charge_failed`, meant for logs.
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

        self.status = Self.decodeStatus(try container.decode(String.self, forKey: .status),
                                        from: container,
                                        decoder: decoder)
    }

    private static func decodeStatus(
        _ rawStatus: String,
        from container: KeyedDecodingContainer<CodingKeys>,
        decoder: Decoder
    ) -> Status {
        switch rawStatus {
        case RawStatus.started, RawStatus.inProgress:
            return .pending
        case RawStatus.succeeded:
            // The purchase's fields sit next to `status` rather than in an object of their own.
            return .succeeded(try? Purchase(from: decoder))
        case RawStatus.failed:
            return .failed(try? container.decodeIfPresent(Failure.self, forKey: .error))
        default:
            Logger.warn(Strings.hostedCheckout.unrecognized_status(rawStatus))
            return .pending
        }
    }

}

extension HostedCheckoutStatusResponse.Purchase: Decodable {}

extension HostedCheckoutStatusResponse.Failure: Decodable {}

extension HostedCheckoutStatusResponse: HTTPResponseBody {}
