//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SKError+Extensions.swift
//
//  Created by Madeline Beyl on 11/4/21.

import Foundation
import StoreKit

extension SKError {

    func toPurchasesErrorCode() -> ErrorCode {
        switch self.code {
        case .unknown,
             .cloudServiceNetworkConnectionFailed,
             .cloudServiceRevoked,
             .overlayTimeout,
             .overlayPresentedInBackgroundScene:
            return .storeProblemError
        case .clientInvalid,
             .paymentNotAllowed,
             .cloudServicePermissionDenied,
             .privacyAcknowledgementRequired:
            return .purchaseNotAllowedError
        case .paymentCancelled,
             .overlayCancelled:
            return .purchaseCancelledError
        case .paymentInvalid,
             .unauthorizedRequestData,
             .missingOfferParams,
             .invalidOfferPrice,
             .invalidSignature,
             .invalidOfferIdentifier:
            return .purchaseInvalidError
        case .storeProductNotAvailable:
            return .productNotAvailableForPurchaseError
        case .ineligibleForOffer,
             .overlayInvalidConfiguration,
             .unsupportedPlatform:
            return .purchaseNotAllowedError
        @unknown default:
            return .unknownError
        }
    }

}
