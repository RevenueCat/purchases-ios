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

// swiftlint:disable file_length multiline_parameters type_body_length

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
        message: String? = nil,
        withUnderlyingError underlyingError: Error? = nil,
        extraUserInfo: [NSError.UserInfoKey: Any]? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {

        let errorCode: ErrorCode
        if case NetworkError.dnsError(_, _, _)? = underlyingError {
            errorCode = .apiEndpointBlockedError
        } else {
            errorCode = .networkError
        }

        return error(with: errorCode,
                     message: message,
                     underlyingError: underlyingError,
                     extraUserInfo: extraUserInfo,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an NSError with the ``ErrorCode/offlineConnection`` code.
     */
    static func offlineConnectionError(
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: .offlineConnectionError,
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
        withSubError subError: Error?,
        extraContext: String? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return backendResponseError(withSubError: subError,
                                    extraContext: extraContext,
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
        underlyingError: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return error(with: ErrorCode.configurationError,
                     message: message, underlyingError: underlyingError,
                     fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Maps an `SKError` to a Error with an ``ErrorCode``. Adds a underlying error in the `NSError.userInfo` dictionary.
     *
     * - Parameter skError: The originating `SKError`.
     */
    static func purchasesError(
        withSKError error: Error,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        switch error {
        case let skError as SKError:
            return skError.asPurchasesError

        default:
            return ErrorUtils.unknownError(
                error: error,
                fileName: fileName, functionName: functionName, line: line
            )
        }
    }

    /**
     * Maps a `StoreKitError` or `Product.PurchaseError`  to an `Error` with an ``ErrorCode``.
     * Adds a underlying error in the `NSError.userInfo` dictionary.
     *
     * - Parameter storeKitError: The originating `StoreKitError` or `Product.PurchaseError`.
     */
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    static func purchasesError(
        withStoreKitError error: Error,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        switch error {
        case let storeKitError as StoreKitError:
            return storeKitError.asPurchasesError
        case let purchasesError as Product.PurchaseError:
            return purchasesError.asPurchasesError
        default:
            return ErrorUtils.unknownError(
                error: error,
                fileName: fileName, functionName: functionName, line: line
            )
        }
    }

    /**
     * Constructs an Error with the ``ErrorCode/purchaseCancelledError`` code.
     *
     * - Note: This error is used when  a purchase is cancelled by the user.
     */
    static func purchaseCancelledError(
        error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = ErrorCode.purchaseCancelledError
        return ErrorUtils.error(with: errorCode,
                                message: errorCode.description,
                                underlyingError: error,
                                fileName: fileName, functionName: functionName, line: line)
    }

    /**
     * Constructs an Error with the ``ErrorCode/productNotAvailableForPurchaseError`` code.
     *
     * #### Related Articles
     * - [`StoreKitError.notAvailableInStorefront`](https://rev.cat/storekit-error-not-available-in-storefront)
     */
    static func productNotAvailableForPurchaseError(
        error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: .productNotAvailableForPurchaseError,
                                underlyingError: error)
    }

    /**
     * Constructs an Error with the ``ErrorCode/productAlreadyPurchasedError`` code.
     */
    static func productAlreadyPurchasedError(
        error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: .productAlreadyPurchasedError,
                                underlyingError: error)
    }

    /**
     * Constructs an Error with the ``ErrorCode/purchaseNotAllowedError`` code.
     */
    static func purchaseNotAllowedError(
        error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: .purchaseNotAllowedError,
                                underlyingError: error)
    }

    /**
     * Constructs an Error with the ``ErrorCode/purchaseInvalidError`` code.
     */
    static func purchaseInvalidError(
        error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: .purchaseInvalidError,
                                underlyingError: error)
    }

    /**
     * Constructs an Error with the ``ErrorCode/ineligibleError`` code.
     */
    static func ineligibleError(
        error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: .ineligibleError,
                                underlyingError: error)
    }

    /**
     * Constructs an Error with the ``ErrorCode/ineligibleError`` code.
     */
    static func invalidPromotionalOfferError(
        error: Error? = nil,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        return ErrorUtils.error(with: .invalidPromotionalOfferError,
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
        withMessage message: String? = nil, error: Error? = nil,
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
                             message: String? = nil,
                             backendMessage: String? = nil,
                             extraUserInfo: [NSError.UserInfoKey: Any]? = nil,
                             fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        let errorCode = backendCode.toPurchasesErrorCode()
        let underlyingError = backendUnderlyingError(backendCode: backendCode, backendMessage: backendMessage)

        return error(with: errorCode,
                     message: message,
                     underlyingError: underlyingError,
                     extraUserInfo: extraUserInfo,
                     fileName: fileName, functionName: functionName, line: line)
    }

}

private extension ErrorUtils {

    static func error(with code: ErrorCode,
                      message: String? = nil,
                      underlyingError: Error? = nil,
                      extraUserInfo: [NSError.UserInfoKey: Any]? = nil,
                      fileName: String = #fileID,
                      functionName: String = #function,
                      line: UInt = #line) -> Error {
        var userInfo = extraUserInfo ?? [:]
        userInfo[NSLocalizedDescriptionKey as NSError.UserInfoKey] = message ?? code.description
        if let underlyingError = underlyingError {
            userInfo[NSUnderlyingErrorKey as NSError.UserInfoKey] = underlyingError
        }
        userInfo[.readableErrorCode] = code.codeName
        userInfo[.file] = "\(fileName):\(line)"
        userInfo[.function] = functionName

        Self.logErrorIfNeeded(
            code,
            message: message,
            fileName: fileName, functionName: functionName, line: line
        )

        let nsError = code as NSError
        let nsErrorWithUserInfo = NSError(domain: nsError.domain,
                                          code: nsError.code,
                                          userInfo: userInfo as [String: Any])
        return nsErrorWithUserInfo as Error
    }

    static func backendResponseError(
        withSubError subError: Error?,
        extraContext: String?,
        fileName: String = #fileID, functionName: String = #function, line: UInt = #line
    ) -> Error {
        var userInfo: [NSError.UserInfoKey: Any] = [:]
        let describableSubError = subError as? DescribableError
        let errorDescription = describableSubError?.description ?? ErrorCode.unexpectedBackendResponseError.description
        userInfo[NSLocalizedDescriptionKey as NSError.UserInfoKey] = errorDescription
        userInfo[NSUnderlyingErrorKey as NSError.UserInfoKey] = subError
        userInfo[.readableErrorCode] = ErrorCode.unexpectedBackendResponseError.codeName
        userInfo[.extraContext] = extraContext
        userInfo[.file] = "\(fileName):\(line)"
        userInfo[.function] = functionName

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

        return backendCode.addingUserInfo(userInfo)
    }

    // swiftlint:disable:next function_body_length
    private static func logErrorIfNeeded(_ code: ErrorCode,
                                         message: String?,
                                         fileName: String = #fileID,
                                         functionName: String = #function,
                                         line: UInt = #line) {
        let formattedMessage: String

        if let message = message, message != code.description {
            // Print both ErrorCode and message only if they're different
            formattedMessage = "\(code.description) \(message)"
        } else {
            formattedMessage = code.description
        }

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
                .productDiscountMissingSubscriptionGroupIdentifierError,
                .customerInfoError,
                .systemInfoError,
                .beginRefundRequestError,
                .apiEndpointBlockedError,
                .invalidPromotionalOfferError,
                .offlineConnectionError:
                Logger.error(
                    formattedMessage,
                    fileName: fileName,
                    functionName: functionName,
                    line: line
                )

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
                Logger.appleError(
                    formattedMessage,
                    fileName: fileName,
                    functionName: functionName,
                    line: line
                )

        @unknown default:
            Logger.error(
                formattedMessage,
                fileName: fileName,
                functionName: functionName,
                line: line
            )
        }
    }
}

extension Error {

    func addingUserInfo(_ userInfo: [String: Any]) -> Error {
        let nsError = self as NSError
        let nsErrorWithUserInfo = NSError(domain: nsError.domain,
                                          code: nsError.code,
                                          userInfo: nsError.userInfo + userInfo)
        return nsErrorWithUserInfo as Error
    }

}

/// Represents where an `Error` was created
struct ErrorSource {

    let file: String
    let function: String
    let line: UInt

}

/// `Equatable` conformance allows `Error` types that contain source information
/// to easily conform to `Equatable`.
extension ErrorSource: Equatable {

    /// However, for ease of testing, we don't actually care if the source of the errors matches
    /// since expectations will be created in the test and therefore will never match.
    static func == (lhs: ErrorSource, rhs: ErrorSource) -> Bool {
        return true
    }

}
