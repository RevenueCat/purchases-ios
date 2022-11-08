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
    case subscriptionNotFoundForCustomer = 7259
    case invalidSubscriberAttributes = 7263
    case invalidSubscriberAttributesBody = 7264
    case purchasedProductMissingInAppleReceipt = 7712

    /**
     * - Parameter code: Generally comes from the backend in json. This may be a String, or an Int, or nothing.
     */
    init(code: Any?) {
        let codeInt = BackendErrorCode.extractCodeNumber(from: code)

        guard let codeInt = codeInt else {
            self = .unknownBackendError
            return
        }

        self = BackendErrorCode(rawValue: codeInt) ?? .unknownBackendError
    }

    static func extractCodeNumber(from codeObject: Any?) -> Int? {
        // The code can be a String or Int
        if let codeString = codeObject as? String {
            return Int(codeString) ?? nil
        }

        return codeObject as? Int
    }

}

extension BackendErrorCode: ExpressibleByIntegerLiteral {

    init(integerLiteral value: IntegerLiteralType) {
        self = BackendErrorCode(rawValue: value) ?? .unknownBackendError
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
        case .invalidReceiptToken,
                .purchasedProductMissingInAppleReceipt:
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
             .subscriptionNotFoundForCustomer,
             .badRequest,
             .internalServerError:
            return .unknownBackendError
        case .unknownError:
            return .unknownError
        }
    }

}
