//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseLinkPreparation.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Foundation

/// What the caller should do once the SDK has been asked to prepare a link that takes the customer out of the
/// app to pay on the web.
@_spi(Internal) public enum ExternalPurchaseLinkPreparation {

    /// Open the link, handing `externalPurchaseTokenID` to the checkout page when there is one.
    case proceed(externalPurchaseTokenID: String?)

    /// Open nothing: the customer declined Apple's disclosure notice, or it could not be shown.
    case stopped

}

extension ExternalPurchaseLinkPreparation: Equatable, Sendable {}

extension ExternalPurchaseLinkPreparation {

    init(preparationResult: ExternalPurchasePreparationResult) {
        switch preparationResult {
        case let .registered(tokenID):
            self = .proceed(externalPurchaseTokenID: tokenID)
        case .unregistered:
            // The customer is still allowed to buy, with nothing for the checkout to tie the purchase back to.
            self = .proceed(externalPurchaseTokenID: nil)
        case .stopped(.cannotMakeExternalPurchases):
            // Nothing was shown and nothing was minted, so the link keeps working exactly as it did before
            // this app took part in the programme.
            self = .proceed(externalPurchaseTokenID: nil)
        case .stopped(.customerCancelledNotice), .stopped(.noticeFailed):
            self = .stopped
        }
    }

}
