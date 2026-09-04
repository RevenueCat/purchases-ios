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

/// The checkout session the backend created with the payment provider.
struct HostedCheckoutResponse: Decodable {

    /// Identifies the session for the whole of its life, including when asking the backend what became
    /// of it once the checkout page is gone.
    let operationSessionId: String

    /// The provider-hosted page to present.
    let checkoutUrl: URL

    /// Where the provider sends the customer once checkout succeeds.
    ///
    /// Returned rather than assumed so that the SDK does not have to know how the backend builds it.
    let successUrl: URL

    /// Where the provider sends the customer once checkout is abandoned.
    let cancelUrl: URL

}

extension HostedCheckoutResponse: HTTPResponseBody {}
