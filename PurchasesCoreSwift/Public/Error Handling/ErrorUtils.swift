//
//  PurchasesErrorUtils.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 7/19/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@objc(RCPurchasesErrorUtils) public class ErrorUtils: NSObject {

    /**
     * Constructs an NSError with the [RCNetworkError] code and a populated [RCUnderlyingErrorKey] in
     * the [NSError.userInfo] dictionary.
     *
     * @param underlyingError The value of the [NSUnderlyingErrorKey] key.
     *
     * @note This error is used when there is an error performing network request returns an error or when there
     * is an [NSJSONSerialization] error.
     */
    @objc public static func networkError(withUnderlyingError underlyingError: Error) -> Error {

        return error(with: .networkError, underlyingError: underlyingError)

    }

    /**
     * Maps an RCBackendError code to a RCPurchasesErrorCode code. Constructs an NSError with the mapped code and adds a
     * [RCUnderlyingErrorKey] in the [NSError.userInfo] dictionary. The backend error code will be mapped using
     * [RCPurchasesErrorCodeFromRCBackendErrorCode].
     *
     * @param backendCode The value of the error key.
     * @param backendMessage The value of the [NSUnderlyingErrorKey] key.
     *
     * @note This error is used when an network request returns an error. The backend error returned is wrapped in
     * this internal error code.
     */
    @objc public static func backendError(withBackendCode backendCode: NSNumber?,
                                          backendMessage: String?) -> Error {
        return backendError(withBackendCode: backendCode, backendMessage: backendMessage, extraUserInfo: nil)
    }

    /**
     * Maps an RCBackendError code to a [RCPurchasesErrorCode] code. Constructs an NSError with the mapped code and adds a
     * [RCUnderlyingErrorKey] in the [NSError.userInfo] dictionary. The backend error code will be mapped using
     * [RCPurchasesErrorCodeFromRCBackendErrorCode].
     *
     * @param backendCode The value of the error key.
     * @param backendMessage The value of the [NSUnderlyingErrorKey] key.
     * @param finishable Will be added to the UserInfo dictionary under the [RCFinishableKey] to indicate if the transaction
     * should be finished after this error.
     *
     * @note This error is used when an network request returns an error. The backend error returned is wrapped in
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
     * Constructs an NSError with the [RCUnexpectedBackendResponseError] code.
     *
     * @note This error is used when an network request returns an unexpected response.
     */
    @objc public static func unexpectedBackendResponseError() -> Error {

        return error(with: ErrorCode.unexpectedBackendResponseError)

    }

    /**
     * Constructs an NSError with the [RCMissingReceiptFileError] code.
     *
     * @note This error is used when the receipt is missing in the device. This can happen if the user is in sandbox or
     * if there are no previous purchases.
     */
    @objc public static func missingReceiptFileError() -> Error {

        return error(with: ErrorCode.missingReceiptFileError)

    }

    /**
     * Constructs an NSError with the [RCInvalidAppUserIdError] code.
     *
     * @note This error is used when the appUserID can't be found in user defaults. This can happen if user defaults
     * are removed manually or if the OS deletes entries when running out of space.
     */
    @objc public static func missingAppUserIDError() -> Error {

        return error(with: ErrorCode.invalidAppUserIdError)

    }

    /**
     * Constructs an NSError with the [RCLogOutAnonymousUserError] code.
     *
     * @note This error is used when logOut is called but the current user is anonymous,
     * as noted by RCPurchaserInfo's isAnonymous property.
     */
    @objc public static func logOutAnonymousUserError() -> Error {

        return error(with: ErrorCode.logOutAnonymousUserError)

    }

    /**
     * Constructs an NSError with the [RCPaymentPendingError] code.
     *
     * @note This error is used during an “ask to buy” flow for a payment. The completion block of the purchasing function
     * will get this error to indicate the guardian has to complete the purchase.
     */
    @objc public static func paymentDeferredError() -> Error {

        return error(with: ErrorCode.paymentPendingError, message: "The payment is deferred.")

    }

    /**
     * Constructs an NSError with the [RCUnknownError] code.
     */
    @objc public static func unknownError() -> Error {

        return error(with: ErrorCode.unknownError)

    }

    /**
     * Maps an SKErrorCode code to a RCPurchasesErrorCode code. Constructs an NSError with the mapped code and adds a
     * [RCUnderlyingErrorKey] in the NSError.userInfo dictionary. The SKErrorCode code will be mapped using
     * [RCPurchasesErrorCodeFromSKError].
     *
     * @param skError The originating [SKError].
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

// TODO(post migration): Change back to internal
public extension ErrorUtils {

    @objc static func backendError(withBackendCode backendCode: NSNumber?,
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
             .operationAlreadyInProgressError,
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
           // NOTE: Behavior change here, before we would make an error with the code that
           // came from the backend. Now we create a BackendErrorCode or an Unknown
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
