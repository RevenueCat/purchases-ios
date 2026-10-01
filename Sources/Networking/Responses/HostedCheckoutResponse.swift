//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutResponse.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation

/// The checkout session the backend has for the customer, either a new one or the one they were given before.
struct HostedCheckoutResponse: Equatable {

    /// Identifies the session for the whole of its life, including when asking the backend what became
    /// of it once the checkout page is gone.
    let operationSessionID: String

    let outcome: Outcome

    enum Outcome: Equatable {

        /// A new session. Any previous one is not coming back.
        case created(Page)

        /// The previous session, which the customer can carry on with.
        case resumed(Page)

        /// The previous session already ended in a purchase, so there is no page to present.
        case succeeded

    }

    /// What a session is presented with.
    struct Page: Equatable {

        /// The provider-hosted page to present.
        let checkoutURL: URL

        /// Where the provider sends the customer once checkout succeeds.
        let successURL: URL

    }

}

extension HostedCheckoutResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case operationSessionID = "operationSessionId"
        case outcome
    }

    private enum RawOutcome {
        static let created = "created"
        static let resumed = "resumed"
        static let succeeded = "succeeded"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.operationSessionID = try container.decode(String.self, forKey: .operationSessionID)

        switch try container.decodeIfPresent(String.self, forKey: .outcome) {
        case RawOutcome.succeeded:
            self.outcome = .succeeded
        case RawOutcome.resumed:
            self.outcome = .resumed(try Page(from: decoder))
        case RawOutcome.created?, nil:
            self.outcome = .created(try Page(from: decoder))
        case let unrecognized?:
            Logger.warn(Strings.hostedCheckout.unrecognized_outcome(unrecognized))
            self.outcome = .created(try Page(from: decoder))
        }
    }

}

extension HostedCheckoutResponse.Page: Decodable {

    // The decoder converts from snake case, which yields `Url` rather than `URL`.
    private enum CodingKeys: String, CodingKey {
        case checkoutURL = "checkoutUrl"
        case successURL = "successUrl"
    }

}

extension HostedCheckoutResponse: HTTPResponseBody {}
