//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendErrorCode.swift
//  Purchases
//
//  Created by Joshua Liebowitz on 7/12/21.
//

import Foundation

/**
 Error codes sent by the RevenueCat backend. This only includes the errors that matter to the SDK
 */
@objc(RCBackendErrorCode) public enum BackendErrorCode: Int, Error {

    @objc(RCBackendUnknownError) case unknownError = 0
    @objc(RCBackendInvalidPlatform) case invalidPlatform = 7000
    @objc(RCBackendStoreProblem) case storeProblem = 7101
    @objc(RCBackendCannotTransferPurchase) case cannotTransferPurchase = 7102
    @objc(RCBackendInvalidReceiptToken) case invalidReceiptToken = 7103
    @objc(RCBackendInvalidAppStoreSharedSecret) case invalidAppStoreSharedSecret = 7104
    @objc(RCBackendInvalidPaymentModeOrIntroPriceNotProvided) case invalidPaymentModeOrIntroPriceNotProvided = 7105
    @objc(RCBackendProductIdForGoogleReceiptNotProvided) case productIdForGoogleReceiptNotProvided = 7106
    @objc(RCBackendInvalidPlayStoreCredentials) case invalidPlayStoreCredentials = 7107
    @objc(RCBackendInternalServerError) case internalServerError = 7110
    @objc(RCBackendEmptyAppUserId) case emptyAppUserId = 7220
    @objc(RCBackendInvalidAuthToken) case invalidAuthToken = 7224
    @objc(RCBackendInvalidAPIKey) case invalidAPIKey = 7225
    @objc(RCBackendBadRequest) case badRequest = 7226
    @objc(RCBackendPlayStoreQuotaExceeded) case playStoreQuotaExceeded = 7229
    @objc(RCBackendPlayStoreInvalidPackageName) case playStoreInvalidPackageName = 7230
    @objc(RCBackendPlayStoreGenericError) case playStoreGenericError = 7231
    @objc(RCBackendUserIneligibleForPromoOffer) case userIneligibleForPromoOffer = 7232
    @objc(RCBackendInvalidAppleSubscriptionKey) case invalidAppleSubscriptionKey = 7234
    @objc(RCBackendInvalidSubscriberAttributes) case invalidSubscriberAttributes = 7263
    @objc(RCBackendInvalidSubscriberAttributesBody) case invalidSubscriberAttributesBody = 7264

}

extension BackendErrorCode {

    // swiftlint:disable cyclomatic_complexity
    func toPurchasesErrorCode() -> ErrorCode {
    // swiftlint:enable cyclomatic_complexity
        switch self {
        case .invalidPlatform:
            return .configurationError
        case .storeProblem:
            return .storeProblemError
        case .cannotTransferPurchase:
            return .receiptAlreadyInUseError
        case .invalidReceiptToken:
            return .invalidReceiptError
        case .invalidAppStoreSharedSecret,
             .invalidAuthToken,
             .invalidAPIKey:
            return .invalidCredentialsError
        case .invalidPaymentModeOrIntroPriceNotProvided,
             .productIdForGoogleReceiptNotProvided:
            return .purchaseInvalidError
        case .emptyAppUserId:
            return .invalidAppUserIdError
        case .invalidAppleSubscriptionKey:
            return .invalidAppleSubscriptionKeyError
        case .userIneligibleForPromoOffer:
            return .ineligibleError
        case .invalidSubscriberAttributes,
             .invalidSubscriberAttributesBody:
            return .invalidSubscriberAttributesError
        case .playStoreInvalidPackageName,
             .playStoreQuotaExceeded,
             .playStoreGenericError,
             .invalidPlayStoreCredentials,
             .badRequest,
             .internalServerError:
            return .unknownBackendError
        case .unknownError:
            return .unknownError
        @unknown default:
            return .unknownError
        }
    }

}
