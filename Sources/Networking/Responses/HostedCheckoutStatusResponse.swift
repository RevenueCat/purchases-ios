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

        /// The purchase is on the customer's account. `transaction` is absent where the backend sends no detail.
        case succeeded(Transaction?)

        /// The session ended without a purchase. `failure` is absent where the backend sends no detail.
        case failed(Failure?)

    }

    /// The transaction a session made, as it appears on the customer's account.
    struct Transaction: Equatable {

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
            // The transaction's fields sit next to `status` rather than in an object of their own.
            return .succeeded(try? Transaction(from: decoder))
        case RawStatus.failed:
            return .failed(try? container.decodeIfPresent(Failure.self, forKey: .error))
        default:
            Logger.warn(Strings.hostedCheckout.unrecognized_status(rawStatus))
            return .pending
        }
    }

}

extension HostedCheckoutStatusResponse.Transaction: Decodable {}

extension HostedCheckoutStatusResponse.Transaction: StoreTransactionType {

    var transactionIdentifier: String { return self.storeTransactionIdentifier }

    var hasKnownPurchaseDate: Bool { return true }
    var hasKnownTransactionIdentifier: Bool { return true }
    var quantity: Int { return 1 }

    var storefront: Storefront? { return nil }
    var jwsRepresentation: String? { return nil }
    var environment: StoreEnvironment? { return self.isSandbox ? .sandbox : .production }
    var reason: TransactionReason? { return .purchase }
    var revocationDate: Date? { return nil }
    var revocationReason: RevocationReason? { return nil }

    /// The web purchase has nothing for StoreKit to finish.
    func finish(_ wrapper: PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        completion()
    }

}

extension HostedCheckoutStatusResponse.Failure: Decodable {}

extension HostedCheckoutStatusResponse: HTTPResponseBody {}
