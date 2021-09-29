//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCPurchasesErrorUtils.swift
//
//  Created by Cesar de la Vega on 7/21/21.
//

import Foundation
import StoreKit

@objc(RCPurchasesErrorUtils) public class ErrorUtils: NSObject {

    /**
     * Constructs an NSError with the ``ErrorCode/networkError`` code and a populated `NSUnderlyingErrorKey` in
     * the `NSError.userInfo` dictionary.
     *
     * - Parameter underlyingError: The value of the `NSUnderlyingErrorKey` key.
     *
     * - Note: This error is used when there is an error performing network request returns an error or when there
     * is an `NSJSONSerialization` error.
     */
    @objc public static func networkError(withUnderlyingError underlyingError: Error) -> Error {
        return error(with: .networkError, underlyingError: underlyingError)
    }

    /**
     * Maps an ``BackendErrorCode`` code to a ``ErrorCode``. code. Constructs an Error with the mapped code and adds a
     * `NSUnderlyingErrorKey` in the `NSError.userInfo` dictionary. The backend error code will be mapped using
     * ``BackendErrorCode/toPurchasesErrorCode()``.
     *
     * - Parameter backendCode: The numerical value of the error.
     * - Parameter backendMessage: The message of the errror contained under the `NSUnderlyingErrorKey` key.
     *
     * - Note: This error is used when an network request returns an error. The backend error returned is wrapped in
     * this internal error code.
     */
    @objc public static func backendError(withBackendCode backendCode: NSNumber?,
                                          backendMessage: String?) -> Error {
        return backendError(withBackendCode: backendCode, backendMessage: backendMessage, extraUserInfo: nil)
    }

    /**
     * Maps an ``BackendErrorCode`` code to an ``ErrorCode``. code. Constructs an Error with the mapped code and adds a
     * `RCUnderlyingErrorKey` in the `NSError.userInfo` dictionary. The backend error code will be mapped using
     * ``BackendErrorCode/toPurchasesErrorCode()``.
     *
     * - Parameter backendCode: The numerical value of the error.
     * - Parameter backendMessage: The message of the errror contained under the `NSUnderlyingErrorKey` key in the
     * UserInfo dictionary.
     * - Parameter finishable: Will be added to the UserInfo dictionary under the ``ErrorDetails/finishableKey`` to
     * indicate if the transaction should be finished after this error.
     *
     * - Note: This error is used when an network request returns an error. The backend error returned is wrapped in
     * this internal error code.
     */
    @objc public static func backendError(withBackendCode backendCode: NSNumber?,
                                          backendMessage: String?,
                                          finishable: Bool) -> Error {
        let extraUserInfo: [NSError.UserInfoKey: Any] = [
            ErrorDetails.finishableKey: finishable
        ]

        return backendError(withBackendCode: backendCode, backendMessage: backendMessage, extraUserInfo: extraUserInfo)
    }

    /**
     * Constructs an Error with the ``ErrorCode/unexpectedBackendResponseError`` code.
     *
     * - Note: This error is used when an network request returns an unexpected response.
     */
    @objc public static func unexpectedBackendResponseError() -> Error {
        return error(with: ErrorCode.unexpectedBackendResponseError)
    }

    /**
     * Constructs an Error with the ``ErrorCode/missingReceiptFileError`` code.
     *
     * - Note: This error is used when the receipt is missing in the device. This can happen if the user is in
     * sandbox or if there are no previous purchases.
     */
    @objc public static func missingReceiptFileError() -> Error {
        return error(with: ErrorCode.missingReceiptFileError)
    }

    /**
     * Constructs an Error with the ``ErrorCode/invalidAppUserIdError`` code.
     *
     * - Note: This error is used when the appUserID can't be found in user defaults. This can happen if user defaults
     * are removed manually or if the OS deletes entries when running out of space.
     */
    @objc public static func missingAppUserIDError() -> Error {
        return error(with: ErrorCode.invalidAppUserIdError)
    }

    /**
     * Constructs an Error with the ``ErrorCode/productDiscountMissingIdentifierError`` code.
     *
     * - Note: This error code is used when attemping to post data about product discounts but the discount is
     * missing an indentifier.
     */
    @objc public static func productDiscountMissingIdentifierError() -> Error {
        return error(with: ErrorCode.productDiscountMissingIdentifierError)
    }

    /**
     * Constructs an Error with the ``ErrorCode/productDiscountMissingSubscriptionGroupIdentifierError`` code.
     *
     * - Note: This error code is used when attemping to post data about product discounts but the discount is
     * missing a subscriptionGroupIndentifier.
     */
    @objc public static func productDiscountMissingSubscriptionGroupIdentifierError() -> Error {
        return error(with: ErrorCode.productDiscountMissingSubscriptionGroupIdentifierError)
    }

    /**
     * Constructs an Error with the ``ErrorCode/invalidAppUserIdError`` code.
     *
     * - Note: This error is used when the appUserID can't be found in user defaults. This can happen if user defaults
     * are removed manually or if the OS deletes entries when running out of space.
     */
    @objc public static func missingAppUserIDForAliasCreationError() -> Error {
        return error(with: ErrorCode.missingAppUserIDForAliasCreationError)
    }

    /**
     * Constructs an Error with the ``ErrorCode/logOutAnonymousUserError`` code.
     *
     * - Note: This error is used when logOut is called but the current user is anonymous,
     * as noted by ``Purchases/isAnonymous`` property.
     */
    @objc public static func logOutAnonymousUserError() -> Error {
        return error(with: ErrorCode.logOutAnonymousUserError)
    }

    /**
     * Constructs an Error with the ``ErrorCode/paymentPendingError`` code.
     *
     * - Note: This error is used during an “ask to buy” flow for a payment. The completion block of the purchasing
     * function will get this error to indicate the guardian has to complete the purchase.
     */
    @objc public static func paymentDeferredError() -> Error {
        return error(with: ErrorCode.paymentPendingError, message: "The payment is deferred.")
    }

    /**
     * Constructs an Error with the ``ErrorCode/unknownError`` code and optional message.
     */
    @objc public static func unknownError(message: String? = nil) -> Error {
        return error(with: ErrorCode.unknownError, message: message)
    }

    /**
     * Constructs an Error with the ``ErrorCode/unknownError`` code.
     */
    @objc public static func unknownError() -> Error {
        return error(with: ErrorCode.unknownError, message: nil)
    }

    /**
     * Constructs an Error with the ``ErrorCode/operationAlreadyInProgressForProductError`` code.
     *
     * - Note: This error is used when a purchase is initiated for a product, but there's already a purchase for the
     * same product in progress.
     */
    @objc public static func operationAlreadyInProgressError() -> Error {
        return error(with: ErrorCode.operationAlreadyInProgressForProductError)
    }

    /**
     * Constructs an Error with the ``ErrorCode/configurationError`` code.
     *
     * - Note: This error is used when the configuration in App Store Connect doesn't match the configuration
     * in the RevenueCat dashboard.
     */
    @objc public static func configurationError(message: String? = nil) -> Error {
        return error(with: ErrorCode.configurationError, message: message)
    }

    /**
     * Maps an `SKError` to a Error with a ``ErrorCode``. Adds a underlying error in the `NSError.userInfo` dictionary.
     *
     * - Parameter skError: The originating `SKError`.
     */
    @objc public static func purchasesError(withSKError skError: Error) -> Error {
        let errorCode = (skError as? SKError)?.toPurchasesErrorCode() ?? .unknownError
        return error(with: errorCode, message: errorCode.description, underlyingError: skError)
    }

}

private extension SKError {

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

extension ErrorUtils {

    static func backendError(withBackendCode backendCode: NSNumber?,
                             backendMessage: String?,
                             extraUserInfo: [NSError.UserInfoKey: Any]? = nil) -> Error {
        let errorCode: ErrorCode
        if let maybeBackendCode = backendCode,
           let backendErrorCode = BackendErrorCode.init(rawValue: maybeBackendCode.intValue) {
            errorCode = backendErrorCode.toPurchasesErrorCode()
        } else {
            errorCode = ErrorCode.unknownBackendError
        }
        let underlyingError = backendUnderlyingError(backendCode: backendCode, backendMessage: backendMessage)

        return error(with: errorCode,
                     message: errorCode.description,
                     underlyingError: underlyingError,
                     extraUserInfo: extraUserInfo)
    }

}

private extension ErrorUtils {

    static func addUserInfo(userInfo: [String: String], error: Error) -> Error {
        let nsError = error as NSError
        let nsErrorWithUserInfo = NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo)
        return nsErrorWithUserInfo as Error
    }

    static func error(with code: ErrorCode,
                      message: String? = nil,
                      underlyingError: Error? = nil,
                      extraUserInfo: [NSError.UserInfoKey: Any]? = nil) -> Error {
        var userInfo = extraUserInfo ?? [:]
        userInfo[NSLocalizedDescriptionKey as NSError.UserInfoKey] = message ?? code.description
        if let maybeUnderlyingError = underlyingError {
            userInfo[NSUnderlyingErrorKey as NSError.UserInfoKey] = maybeUnderlyingError
        }
        userInfo[ErrorDetails.readableErrorCodeKey] = code.codeName

        switch code {
        case .networkError,
             .unknownError,
             .receiptAlreadyInUseError,
             .unexpectedBackendResponseError,
             .invalidReceiptError,
             .invalidAppUserIdError,
             .operationAlreadyInProgressForProductError,
             .unknownBackendError,
             .invalidSubscriberAttributesError,
             .logOutAnonymousUserError:
            Logger.error(code.description)
        case .purchaseCancelledError,
             .storeProblemError,
             .purchaseNotAllowedError,
             .purchaseInvalidError,
             .productNotAvailableForPurchaseError,
             .productAlreadyPurchasedError,
             .missingReceiptFileError,
             .invalidCredentialsError,
             .invalidAppleSubscriptionKeyError,
             .ineligibleError,
             .insufficientPermissionsError,
             .paymentPendingError:
            Logger.appleError(code.description)
        default:
            break
        }
        let nsError = code as NSError
        let nsErrorWithUserInfo = NSError(domain: nsError.domain, code: nsError.code,
                userInfo: userInfo as [String: Any])
        return nsErrorWithUserInfo as Error
    }

    static func backendUnderlyingError(backendCode: NSNumber?, backendMessage: String?) -> Error {
        let error: Error
        if let maybeBackendCode = backendCode,
           let backendError = BackendErrorCode.init(rawValue: maybeBackendCode.intValue) {
            error = backendError
        } else {
            error = BackendErrorCode.unknownError
        }

        let userInfo = [
            NSLocalizedDescriptionKey: backendMessage ?? ""
        ]
        let errorWithUserInfo = addUserInfo(userInfo: userInfo, error: error)
        return errorWithUserInfo
    }

}
