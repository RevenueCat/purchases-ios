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
// swiftlint:disable missing_docs

import Foundation

/// A checkout session created with the payment provider, and everything needed to present it and to tell
/// when the customer has come back from it.
@_spi(Internal) public struct HostedCheckoutSession {

    @_spi(Internal) public let operationSessionID: String

    /// The customer the session was created for, who need not be the one logged in by the time it is settled.
    @_spi(Internal) public let appUserID: String

    /// The provider-hosted page to present.
    @_spi(Internal) public let checkoutURL: URL

    /// Where the provider sends the customer once checkout succeeds.
    @_spi(Internal) public let successURL: URL

    @_spi(Internal) public init(operationSessionID: String,
                                appUserID: String,
                                checkoutURL: URL,
                                successURL: URL) {
        self.operationSessionID = operationSessionID
        self.appUserID = appUserID
        self.checkoutURL = checkoutURL
        self.successURL = successURL
    }

}

extension HostedCheckoutSession: Equatable, Sendable {}

/// What the backend needs to say how a checkout session ended, which is less than presenting it takes.
@_spi(Internal) public struct HostedCheckoutSessionID {

    @_spi(Internal) public let operationSessionID: String

    /// The customer the session was created for, who need not be the one logged in by the time it is settled.
    @_spi(Internal) public let appUserID: String

    @_spi(Internal) public init(operationSessionID: String, appUserID: String) {
        self.operationSessionID = operationSessionID
        self.appUserID = appUserID
    }

}

extension HostedCheckoutSessionID: Equatable, Sendable {}

extension HostedCheckoutSession {

    @_spi(Internal) public var id: HostedCheckoutSessionID {
        return .init(operationSessionID: self.operationSessionID, appUserID: self.appUserID)
    }

    init(operationSessionID: String, page: HostedCheckoutResponse.Page, appUserID: String) {
        self.init(operationSessionID: operationSessionID,
                  appUserID: appUserID,
                  checkoutURL: page.checkoutURL,
                  successURL: page.successURL)
    }

}
