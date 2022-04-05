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
    func toPurchasesError() -> Error {
        switch self.code {
        case .cloudServiceNetworkConnectionFailed,
             .cloudServiceRevoked,
             .overlayTimeout,
             .overlayPresentedInBackgroundScene:
            return ErrorUtils.storeProblemError(error: self)
        case .clientInvalid,
             .paymentNotAllowed,
             .cloudServicePermissionDenied,
             .privacyAcknowledgementRequired:
            return ErrorUtils.purchaseNotAllowedError(error: self)
        case .paymentCancelled,
             .overlayCancelled:
            return ErrorUtils.purchaseCancelledError(error: self)
        case .paymentInvalid,
            .unauthorizedRequestData:
            return ErrorUtils.purchaseInvalidError(error: self)
        case .storeProductNotAvailable:
            return ErrorUtils.productNotAvailableForPurchaseError(error: self)
        case .overlayInvalidConfiguration,
             .unsupportedPlatform:
            return ErrorUtils.purchaseNotAllowedError(error: self)
        case .ineligibleForOffer:
            return ErrorUtils.ineligibleError(error: self)
        case .missingOfferParams,
            .invalidOfferPrice,
            .invalidSignature,
            .invalidOfferIdentifier:
            return ErrorUtils.invalidPromotionalOfferError(error: self)
        case .unknown:
            if let error = self.userInfo[NSUnderlyingErrorKey] as? NSError {
                switch (error.domain, error.code) {
                case ("ASDServerErrorDomain", 3532): // "You’re currently subscribed to this"
                    // See https://github.com/RevenueCat/purchases-ios/issues/392
                    return ErrorUtils.productAlreadyPurchasedError(error: self)

                default: break
                }
            }

            return ErrorUtils.storeProblemError(error: self)

        @unknown default:
            return ErrorUtils.unknownError(error: self)
        }
    }

}
