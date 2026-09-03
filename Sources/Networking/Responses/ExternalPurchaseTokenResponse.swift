//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseTokenResponse.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation

/// The response is only read for the identifier the checkout page needs. The endpoint returns more
/// fields, which are ignored.
struct ExternalPurchaseTokenResponse: Decodable {

    /// The identifier of the token registration, to be handed to the checkout page.
    let id: String

}

extension ExternalPurchaseTokenResponse: HTTPResponseBody {}
