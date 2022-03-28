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

    // swiftlint:disable:next cyclomatic_complexity
    func toPurchasesErrorCode() -> ErrorCode {
        switch self.code {
        case .cloudServiceNetworkConnectionFailed,
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
        case .unknown:
            if let error = self.userInfo[NSUnderlyingErrorKey] as? NSError {
                switch (error.domain, error.code) {
                case ("ASDServerErrorDomain", 3532): // "You’re currently subscribed to this"
                    // See https://github.com/RevenueCat/purchases-ios/issues/392
                    return .productAlreadyPurchasedError

                default: break
                }
            }

            return .storeProblemError

        @unknown default:
            return .unknownError
        }
    }

}
