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

extension SKError: PurchasesErrorConvertible {

    var asPurchasesError: PurchasesError {
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
                switch error.domain {
                case ASDServerError.domain:
                    switch ASDServerError.Code(rawValue: error.code) {
                    case .currentlySubscribed:
                        return ErrorUtils.productAlreadyPurchasedError(error: self)

                    default: break
                    }

                default: break
                }
            }

            return ErrorUtils.storeProblemError(error: self)

        @unknown default:
            switch SKError.UndocumentedCode(rawValue: self.code.rawValue) {
            case .unhandledException:
                if let error = self.userInfo[NSUnderlyingErrorKey] as? NSError {
                    switch error.domain {
                    case AMSError.domain:
                        switch AMSError.Code(rawValue: error.code) {
                            // See https://github.com/RevenueCat/purchases-ios/issues/1445
                            // Cancellations sometimes show up as undocumented errors instead of regular cancellations
                        case .paymentSheetFailed:
                            return ErrorUtils.purchaseCancelledError(error: self)

                        default: break
                        }

                    default: break
                    }
                }

            default: break
            }

            return ErrorUtils.unknownError(error: self)
        }
    }

}

extension SKError.Code {

    var trackingDescription: String {
        switch self {
        case .unknown:
            return "unknown"
        case .clientInvalid:
            return "client_invalid"
        case .paymentCancelled:
            return "payment_cancelled"
        case .paymentInvalid:
            return "payment_invalid"
        case .paymentNotAllowed:
            return "payment_not_allowed"
        case .storeProductNotAvailable:
            return "store_product_not_available"
        case .cloudServicePermissionDenied:
            return "cloud_service_permission_denied"
        case .cloudServiceNetworkConnectionFailed:
            return "cloud_service_network_connection_failed"
        case .cloudServiceRevoked:
            return "cloud_service_revoked"
        case .privacyAcknowledgementRequired:
            return "privacy_acknowledgement_required"
        case .unauthorizedRequestData:
            return "unauthorized_request_data"
        case .invalidOfferIdentifier:
            return "invalid_offer_identifier"
        case .invalidSignature:
            return "invalid_signature"
        case .missingOfferParams:
            return "missing_offer_parameters"
        case .invalidOfferPrice:
            return "invalid_offer_price"
        case .overlayCancelled:
            return "overlay_cancelled"
        case .overlayInvalidConfiguration:
            return "overlay_invalid_configuration"
        case .overlayTimeout:
            return "overlay_timeout"
        case .ineligibleForOffer:
            return "ineligible_for_offer"
        case .unsupportedPlatform:
            return "unsupported_platform"
        case .overlayPresentedInBackgroundScene:
            return "overlay_presented_in_background_scene"
        @unknown default:
            return "unknown_store_kit_error"
        }
    }

}

private extension SKError {

    enum UndocumentedCode: Int {

        // See https://github.com/RevenueCat/purchases-ios/issues/1445
        case unhandledException = 907

    }

}

private enum ASDServerError {

    static let domain = "ASDServerErrorDomain"

    enum Code: Int {

        // See https://github.com/RevenueCat/purchases-ios/issues/392
        case currentlySubscribed = 3532

    }

}

private enum AMSError {

    static let domain = "AMSErrorDomain"

    enum Code: Int {

        // See https://github.com/RevenueCat/purchases-ios/issues/1445
        case paymentSheetFailed = 6

    }

}
