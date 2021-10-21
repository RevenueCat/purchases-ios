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
//
//  Created by Joshua Liebowitz on 7/12/21.
//

import Foundation

/**
 Error codes sent by the RevenueCat backend. This only includes the errors that matter to the SDK
 */
enum BackendErrorCode: Int, Error {

    case unknownBackendError = -1 // Some backend problem we don't know the specifics of.
    case unknownError = 0 // We don't know what happened.
    case invalidPlatform = 7000
    case storeProblem = 7101
    case cannotTransferPurchase = 7102
    case invalidReceiptToken = 7103
    case invalidAppStoreSharedSecret = 7104
    case invalidPaymentModeOrIntroPriceNotProvided = 7105
    case productIdForGoogleReceiptNotProvided = 7106
    case invalidPlayStoreCredentials = 7107
    case internalServerError = 7110
    case emptyAppUserId = 7220
    case invalidAuthToken = 7224
    case invalidAPIKey = 7225
    case badRequest = 7226
    case playStoreQuotaExceeded = 7229
    case playStoreInvalidPackageName = 7230
    case playStoreGenericError = 7231
    case userIneligibleForPromoOffer = 7232
    case invalidAppleSubscriptionKey = 7234
    case invalidSubscriberAttributes = 7263
    case invalidSubscriberAttributesBody = 7264

    /**
     * - Parameter maybeCode: Generally comes from the backend in json. This may be a String, or an Int, or nothing.
     */
    init(maybeCode: Any?) {
        let maybeCodeInt = BackendErrorCode.maybeInt(maybeCodeObject: maybeCode)

        guard let codeInt = maybeCodeInt else {
            self = .unknownBackendError
            return
        }

        self = BackendErrorCode(rawValue: codeInt) ?? .unknownBackendError
    }

    static func maybeInt(maybeCodeObject: Any?) -> Int? {
        // The code can be a String or Int
        if let codeString = maybeCodeObject as? String {
            return Int(codeString) ?? nil
        }

        return maybeCodeObject as? Int
    }

}

extension BackendErrorCode {

    // swiftlint:disable cyclomatic_complexity
    /// Turns ``BackendErrorCode``(RCBackendErrorCode) codes into ``ErrorCode``(RCPurchasesErrorCode) error codes
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
        case .unknownBackendError,
             .playStoreInvalidPackageName,
             .playStoreQuotaExceeded,
             .playStoreGenericError,
             .invalidPlayStoreCredentials,
             .badRequest,
             .internalServerError:
            return .unknownBackendError
        case .unknownError:
            return .unknownError
        }
    }

}
