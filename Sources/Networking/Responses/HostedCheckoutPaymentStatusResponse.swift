//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutPaymentStatusResponse.swift
//
//  Created by Antonio Pallares on 25/9/26.

import Foundation

/// Whether the customer paid for a checkout session, as the payment provider sees it.
///
/// Unlike ``HostedCheckoutStatusResponse``, the backend asks the payment provider to answer this, so it is
/// asked once after the customer dismisses the checkout rather than polled.
struct HostedCheckoutPaymentStatusResponse: Equatable {

    let paymentStatus: PaymentStatus

    enum PaymentStatus: Equatable {

        /// The customer has not paid.
        case open

        /// A payment is under way, or the session has already ended. The caller should poll the session's status.
        case processing

        /// The backend could not read the payment provider, or sent a status this version of the SDK does
        /// not know.
        case unknown

    }

}

extension HostedCheckoutPaymentStatusResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case paymentStatus
    }

    private enum RawPaymentStatus {
        static let open = "open"
        static let processing = "processing"
        static let unknown = "unknown"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.paymentStatus = Self.decodePaymentStatus(try container.decode(String.self, forKey: .paymentStatus))
    }

    private static func decodePaymentStatus(_ rawPaymentStatus: String) -> PaymentStatus {
        switch rawPaymentStatus {
        case RawPaymentStatus.open:
            return .open
        case RawPaymentStatus.processing:
            return .processing
        case RawPaymentStatus.unknown:
            return .unknown
        default:
            Logger.warn(Strings.hostedCheckout.unrecognized_payment_status(rawPaymentStatus))
            return .unknown
        }
    }

}

extension HostedCheckoutPaymentStatusResponse: HTTPResponseBody {}
