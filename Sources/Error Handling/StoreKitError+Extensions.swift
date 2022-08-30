//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitError+Extensions.swift
//
//  Created by Nacho Soto on 12/14/21.

import StoreKit

/// - SeeAlso: SKError+Extensions
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension StoreKitError: PurchasesErrorConvertible {

    var asPurchasesError: PurchasesError {
        switch self {
        case .userCancelled:
            return ErrorUtils.purchaseCancelledError(error: self)

        case let .networkError(error):
            return ErrorUtils.networkError(withUnderlyingError: error)

        case let .systemError(error):
            return ErrorUtils.storeProblemError(error: error)

        case .notAvailableInStorefront:
            return ErrorUtils.productNotAvailableForPurchaseError(error: self)

#if swift(>=5.6)
        case .notEntitled:
            return ErrorUtils.storeProblemError(error: self)
#endif

        case .unknown:
            /// See also https://github.com/RevenueCat/purchases-ios/issues/392
            /// `StoreKitError` doesn't conform to `CustomNSError` as of `iOS 15.2`
            /// so we can't extract any additional information like we do on `SKError.toPurchasesErrorCode`
            return ErrorUtils.storeProblemError(error: self)

        @unknown default:
            return ErrorUtils.unknownError(error: self)
        }
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension Product.PurchaseError: PurchasesErrorConvertible {

    var asPurchasesError: PurchasesError {
        switch self {
        case .invalidQuantity:
            return ErrorUtils.storeProblemError(error: self)

        case .productUnavailable:
            return ErrorUtils.productNotAvailableForPurchaseError(error: self)

        case .purchaseNotAllowed:
            return ErrorUtils.purchaseNotAllowedError(error: self)

        case .ineligibleForOffer:
            return ErrorUtils.ineligibleError(error: self)

        case
                .invalidOfferIdentifier,
                .invalidOfferPrice,
                .invalidOfferSignature,
                .missingOfferParameters:
            return ErrorUtils.invalidPromotionalOfferError(error: self)

        @unknown default:
            return ErrorUtils.unknownError(error: self)
        }
    }

}
