//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutSession.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Foundation

/// A checkout session created with the payment provider, and everything needed to present it and to tell
/// when the customer has come back from it.
@_spi(Internal) public struct HostedCheckoutSession {

    /// Identifies the session for the whole of its life, including when asking the backend what became of it
    /// once the checkout page is gone.
    @_spi(Internal) public let operationSessionID: String

    /// The provider-hosted page to present.
    @_spi(Internal) public let checkoutURL: URL

    /// Where the provider sends the customer once checkout succeeds.
    @_spi(Internal) public let successURL: URL

    /// Where the provider sends the customer once checkout is abandoned.
    @_spi(Internal) public let cancelURL: URL

    /// Creates a session. Public so that `RevenueCatUI` can build one for its tests and previews.
    @_spi(Internal) public init(operationSessionID: String,
                                checkoutURL: URL,
                                successURL: URL,
                                cancelURL: URL) {
        self.operationSessionID = operationSessionID
        self.checkoutURL = checkoutURL
        self.successURL = successURL
        self.cancelURL = cancelURL
    }

}

extension HostedCheckoutSession: Equatable, Sendable {}

extension HostedCheckoutSession {

    init(response: HostedCheckoutResponse) {
        self.init(operationSessionID: response.operationSessionID,
                  checkoutURL: response.checkoutURL,
                  successURL: response.successURL,
                  cancelURL: response.cancelURL)
    }

}
