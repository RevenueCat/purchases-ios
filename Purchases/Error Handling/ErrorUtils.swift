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

// swiftlint:disable file_length multiline_parameters

enum ErrorUtils {

    /**
     * Constructs an NSError with the ``ErrorCode/networkError`` code and a populated `NSUnderlyingErrorKey` in
     * the `NSError.userInfo` dictionary.
     *
     * - Parameter underlyingError: The value of the `NSUnderlyingErrorKey` key.
     *
     * - Note: This error is used when there is an error performing network request returns an error or when there
     * is an `NSJSONSerialization` error.
     */
    static func networkError(
        withUnderlyingError underlyingError: Error, generatedBy: String? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: .networkError, underlyingError: underlyingError, generatedBy: generatedBy,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Maps a ``BackendErrorCode`` code to a ``ErrorCode``. code. Constructs an Error with the mapped code and adds a
     * `NSUnderlyingErrorKey` in the `NSError.userInfo` dictionary. The backend error code will be mapped using
     * ``BackendErrorCode/toPurchasesErrorCode()``.
     *
     * - Parameter backendCode: The numerical value of the error.
     * - Parameter backendMessage: The message of the errror contained under the `NSUnderlyingErrorKey` key.
     *
     * - Note: This error is used when an network request returns an error. The backend error returned is wrapped in
     * this internal error code.
     */
    static func backendError(
        withBackendCode backendCode: BackendErrorCode, backendMessage: String?,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return backendError(withBackendCode: backendCode, backendMessage: backendMessage, extraUserInfo: nil,
                            fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Maps a ``BackendErrorCode`` code to an ``ErrorCode``. code. Constructs an Error with the mapped code and adds a
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
    static func backendError(
        withBackendCode backendCode: BackendErrorCode,
        backendMessage: String?,
        finishable: Bool,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let extraUserInfo: [NSError.UserInfoKey: Any] = [
            ErrorDetails.finishableKey: finishable
        ]

        return backendError(withBackendCode: backendCode, backendMessage: backendMessage, extraUserInfo: extraUserInfo,
                            fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/unexpectedBackendResponseError`` code.
     *
     * - Note: This error is used when a network request returns an unexpected response.
     */
    static func unexpectedBackendResponseError(
        extraUserInfo: [NSError.UserInfoKey: Any]? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.unexpectedBackendResponseError, extraUserInfo: extraUserInfo,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/unexpectedBackendResponseError`` code which contains an underlying
     * ``UnexpectedBackendResponseSubErrorCode``
     *
     * - Note: This error is used when a network request returns an unexpected response and we can determine some
     * of what went wrong with the response.
     */
    static func unexpectedBackendResponse(
        withSubError maybeSubError: Error?,
        generatedBy maybeGeneratedBy: String? = nil,
        extraContext maybeExtraContext: String? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return backendResponseError(withSubError: maybeSubError,
                                    generatedBy: maybeGeneratedBy,
                                    extraContext: maybeExtraContext,
                                    fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/missingReceiptFileError`` code.
     *
     * - Note: This error is used when the receipt is missing in the device. This can happen if the user is in
     * sandbox or if there are no previous purchases.
     */
    static func missingReceiptFileError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.missingReceiptFileError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/invalidAppUserIdError`` code.
     *
     * - Note: This error is used when the appUserID can't be found in user defaults. This can happen if user defaults
     * are removed manually or if the OS deletes entries when running out of space.
     */
    static func missingAppUserIDError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.invalidAppUserIdError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/productDiscountMissingIdentifierError`` code.
     *
     * - Note: This error code is used when attemping to post data about product discounts but the discount is
     * missing an indentifier.
     */
    static func productDiscountMissingIdentifierError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.productDiscountMissingIdentifierError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/productDiscountMissingSubscriptionGroupIdentifierError`` code.
     *
     * - Note: This error code is used when attemping to post data about product discounts but the discount is
     * missing a subscriptionGroupIndentifier.
     */
    static func productDiscountMissingSubscriptionGroupIdentifierError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.productDiscountMissingSubscriptionGroupIdentifierError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/invalidAppUserIdError`` code.
     *
     * - Note: This error is used when the appUserID can't be found in user defaults. This can happen if user defaults
     * are removed manually or if the OS deletes entries when running out of space.
     */
    static func missingAppUserIDForAliasCreationError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.missingAppUserIDForAliasCreationError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/logOutAnonymousUserError`` code.
     *
     * - Note: This error is used when logOut is called but the current user is anonymous,
     * as noted by ``Purchases/isAnonymous`` property.
     */
    static func logOutAnonymousUserError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.logOutAnonymousUserError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/paymentPendingError`` code.
     *
     * - Note: This error is used during an “ask to buy” flow for a payment. The completion block of the purchasing
     * function will get this error to indicate the guardian has to complete the purchase.
     */
    static func paymentDeferredError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.paymentPendingError, message: "The payment is deferred.",
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/unknownError`` code and optional message.
     */
    static func unknownError(
        message: String? = nil, error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: ErrorCode.unknownError, message: message, underlyingError: error,
                                fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/operationAlreadyInProgressForProductError`` code.
     *
     * - Note: This error is used when a purchase is initiated for a product, but there's already a purchase for the
     * same product in progress.
     */
    static func operationAlreadyInProgressError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.operationAlreadyInProgressForProductError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/configurationError`` code.
     *
     * - Note: This error is used when the configuration in App Store Connect doesn't match the configuration
     * in the RevenueCat dashboard.
     */
    static func configurationError(
        message: String? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.configurationError, message: message,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Maps an `SKError` to a Error with a ``ErrorCode``. Adds a underlying error in the `NSError.userInfo` dictionary.
     *
     * - Parameter skError: The originating `SKError`.
     */
    static func purchasesError(
        withSKError skError: Error,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = (skError as? SKError)?.toPurchasesErrorCode() ?? .unknownError
        return error(with: errorCode, message: errorCode.description, underlyingError: skError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Maps a `StoreKitError` to an `Error` with a ``ErrorCode``.
     * Adds a underlying error in the `NSError.userInfo` dictionary.
     *
     * - Parameter skError: The originating `StoreKitError`.
     */
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    static func purchasesError(withStoreKitError storeKitError: Error) -> Error {
        return (storeKitError as? StoreKitError)?.toPurchasesError() ?? self.unknownError()
    }

    /**
     * Constructs an Error with the ``ErrorCode/purchaseCancelledError`` code.
     *
     * - Note: This error is used when  a purchase is cancelled by the user.
     */
    static func purchaseCancelledError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = ErrorCode.purchaseCancelledError
        return ErrorUtils.error(with: errorCode,
                                message: errorCode.description,
                                underlyingError: nil,
                                fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/productNotAvailableForPurchaseError`` code.
     *
     * - Seealso: ``StoreKitError.notAvailableInStorefront``
     */
    static func productNotAvailableForPurchaseError(
        error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: .productNotAvailableForPurchaseError,
                                underlyingError: error)
    }

    /**
     * Constructs an Error with the ``ErrorCode/storeProblemError`` code.
     *
     * - Note: This error is used when there is a problem with the App Store.
     */
    static func storeProblemError(
        withMessage message: String? = nil, error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = ErrorCode.storeProblemError
        return ErrorUtils.error(with: errorCode,
                                message: message,
                                underlyingError: error,
                                fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/customerInfoError`` code.
     *
     * - Note: This error is used when there is a problem related to the customer info.
     */
    static func customerInfoError(
        withMessage message: String, error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = ErrorCode.customerInfoError
        return ErrorUtils.error(with: errorCode,
                                message: message,
                                underlyingError: error,
                                fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/systemInfoError`` code.
     *
     * - Note: This error is used when there is a problem related to the system info.
     */
    static func systemInfoError(
        withMessage message: String, error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = ErrorCode.systemInfoError
        return ErrorUtils.error(with: errorCode,
                                message: message,
                                underlyingError: error,
                                fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/beginRefundRequestError`` code.
     *
     * - Note: This error is used when there is a problem beginning a refund request.
     */
    static func beginRefundRequestError(
        withMessage message: String, error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = ErrorCode.beginRefundRequestError
        return ErrorUtils.error(with: errorCode,
                                message: message,
                                underlyingError: error,
                                fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/productRequestTimedOut`` code.
     *
     * - Note: This error is used  when fetching products times out.
     */
    static func productRequestTimedOutError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: .productRequestTimedOut,
                                fileName: fileName, functionName: functionName, line: line)
    }

}

extension ErrorUtils {

    static func backendError(withBackendCode backendCode: BackendErrorCode,
                             backendMessage maybeBackendMessage: String?,
                             extraUserInfo: [NSError.UserInfoKey: Any]? = nil,
                             fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = backendCode.toPurchasesErrorCode()
        let underlyingError = backendUnderlyingError(backendCode: backendCode, backendMessage: maybeBackendMessage)

        return error(with: errorCode,
                     message: errorCode.description,
                     underlyingError: underlyingError,
                     extraUserInfo: extraUserInfo,
                     fileName: fileName, functionName: functionName, line: line)
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
                      generatedBy: String? = nil,
                      extraUserInfo: [NSError.UserInfoKey: Any]? = nil,
                      fileName: String = #fileID,
                      functionName: String = #function,
                      line: UInt = #line) -> Error {
        var userInfo = extraUserInfo ?? [:]
        userInfo[NSLocalizedDescriptionKey as NSError.UserInfoKey] = message ?? code.description
        if let maybeUnderlyingError = underlyingError {
            userInfo[NSUnderlyingErrorKey as NSError.UserInfoKey] = maybeUnderlyingError
        }
        userInfo[ErrorDetails.generatedByKey] = generatedBy
        userInfo[ErrorDetails.readableErrorCodeKey] = code.codeName
        userInfo[ErrorDetails.fileKey] = "\(fileName):\(line)"
        userInfo[ErrorDetails.functionKey] = functionName

        Self.logErrorIfNeeded(code,
                              fileName: fileName, functionName: functionName, line: line)

        let nsError = code as NSError
        let nsErrorWithUserInfo = NSError(domain: nsError.domain,
                                          code: nsError.code,
                                          userInfo: userInfo as [String: Any])
        return nsErrorWithUserInfo as Error
    }

    static func backendResponseError(
        withSubError maybeSubError: Error?,
        generatedBy maybeGeneratedBy: String?,
        extraContext maybeExtraContext: String?,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        var userInfo: [NSError.UserInfoKey: Any] = [:]
        let describableSubError = maybeSubError as? DescribableError
        let errorDescription = describableSubError?.description ?? ErrorCode.unexpectedBackendResponseError.description
        userInfo[NSLocalizedDescriptionKey as NSError.UserInfoKey] = errorDescription
        userInfo[NSUnderlyingErrorKey as NSError.UserInfoKey] = maybeSubError
        userInfo[ErrorDetails.readableErrorCodeKey] = ErrorCode.unexpectedBackendResponseError.codeName
        userInfo[ErrorDetails.generatedByKey] = maybeGeneratedBy
        userInfo[ErrorDetails.extraContextKey] = maybeExtraContext
        userInfo[ErrorDetails.fileKey] = "\(fileName):\(line)"
        userInfo[ErrorDetails.functionKey] = functionName

        let nsError = ErrorCode.unexpectedBackendResponseError as NSError
        let nsErrorWithUserInfo = NSError(domain: nsError.domain,
                                          code: nsError.code,
                                          userInfo: userInfo as [String: Any])
        return nsErrorWithUserInfo as Error
    }

    static func backendUnderlyingError(backendCode: BackendErrorCode, backendMessage: String?) -> Error {
        let userInfo = [
            NSLocalizedDescriptionKey: backendMessage ?? ""
        ]
        let errorWithUserInfo = addUserInfo(userInfo: userInfo, error: backendCode)
        return errorWithUserInfo
    }

    private static func logErrorIfNeeded(_ code: ErrorCode,
                                         fileName: String = #fileID,
                                         functionName: String = #function,
                                         line: UInt = #line) {
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
                .logOutAnonymousUserError,
                .receiptInUseByOtherSubscriberError,
                .configurationError,
                .unsupportedError,
                .emptySubscriberAttributes,
                .productDiscountMissingIdentifierError,
                .missingAppUserIDForAliasCreationError,
                .productDiscountMissingSubscriptionGroupIdentifierError,
                .customerInfoError,
                .systemInfoError,
                .beginRefundRequestError:
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
                .paymentPendingError,
                .productRequestTimedOut:
            Logger.appleError(code.description)

        @unknown default:
            Logger.error(code.description)
        }
    }
}
