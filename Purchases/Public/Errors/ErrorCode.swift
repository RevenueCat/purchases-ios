//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorCode.swift
//
//  Created by Joshua Liebowitz on 7/8/21.
//

import Foundation

/**
 Error codes used by the Purchases SDK
 */
@objc(RCPurchasesErrorCode) public enum ErrorCode: Int, Error {

    @objc(RCUnknownError) case unknownError = 0
    @objc(RCPurchaseCancelledError) case purchaseCancelledError = 1
    @objc(RCStoreProblemError) case storeProblemError = 2
    @objc(RCPurchaseNotAllowedError) case purchaseNotAllowedError = 3
    @objc(RCPurchaseInvalidError) case purchaseInvalidError = 4
    @objc(RCProductNotAvailableForPurchaseError) case productNotAvailableForPurchaseError = 5
    @objc(RCProductAlreadyPurchasedError) case productAlreadyPurchasedError = 6
    @objc(RCReceiptAlreadyInUseError) case receiptAlreadyInUseError = 7
    @objc(RCInvalidReceiptError) case invalidReceiptError = 8
    @objc(RCMissingReceiptFileError) case missingReceiptFileError = 9
    @objc(RCNetworkError) case networkError = 10
    @objc(RCInvalidCredentialsError) case invalidCredentialsError = 11
    @objc(RCUnexpectedBackendResponseError) case unexpectedBackendResponseError = 12
    @objc(RCReceiptInUseByOtherSubscriberError) case receiptInUseByOtherSubscriberError = 13
    @objc(RCInvalidAppUserIdError) case invalidAppUserIdError = 14
    @objc(RCOperationAlreadyInProgressForProductError) case operationAlreadyInProgressForProductError = 15
    @objc(RCUnknownBackendError) case unknownBackendError = 16
    @objc(RCInvalidAppleSubscriptionKeyError) case invalidAppleSubscriptionKeyError = 17
    @objc(RCIneligibleError) case ineligibleError = 18
    @objc(RCInsufficientPermissionsError) case insufficientPermissionsError = 19
    @objc(RCPaymentPendingError) case paymentPendingError = 20
    @objc(RCInvalidSubscriberAttributesError) case invalidSubscriberAttributesError = 21
    @objc(RCLogOutAnonymousUserError) case logOutAnonymousUserError = 22
    @objc(RCConfigurationError) case configurationError = 23
    @objc(RCUnsupportedError) case unsupportedError = 24
    @objc(RCEmptySubscriberAttributesError) case emptySubscriberAttributes = 25
    @objc(RCProductDiscountMissingIdentifierError) case productDiscountMissingIdentifierError = 26
    @objc(RCMissingAppUserIDForAliasCreationError) case missingAppUserIDForAliasCreationError = 27
    @objc(RCProductDiscountMissingSubscriptionGroupIdentifierError)
    case productDiscountMissingSubscriptionGroupIdentifierError = 28

}

extension ErrorCode: CaseIterable { }

extension ErrorCode: DescribableError {

    public var description: String {
        switch self {
        case .networkError:
            return "Error performing request."
        case .unknownError:
            return "Unknown error."
        case .purchaseCancelledError:
            return "Purchase was cancelled."
        case .storeProblemError:
        #if os(macOS) || targetEnvironment(macCatalyst)
            // See https://github.com/RevenueCat/purchases-ios/issues/370
            return "There was a problem with the App Store. This could also indicate the purchase dialog was cancelled."
        #else
            return "There was a problem with the App Store."
        #endif
        case .purchaseNotAllowedError:
            return "The device or user is not allowed to make the purchase."
        case .purchaseInvalidError:
            return "One or more of the arguments provided are invalid."
        case .productNotAvailableForPurchaseError:
            return "The product is not available for purchase."
        case .productAlreadyPurchasedError:
            return "This product is already active for the user."
        case .receiptAlreadyInUseError:
            return "There is already another active subscriber using the same receipt."
        case .missingReceiptFileError:
            return "The receipt is missing."
        case .invalidCredentialsError:
            return "There was a credentials issue. Check the underlying error for more details."
        case .unexpectedBackendResponseError:
            return "Received malformed response from the backend."
        case .invalidReceiptError:
            return "The receipt is not valid."
        case .invalidAppUserIdError:
            return "The app user id is not valid."
        case .operationAlreadyInProgressForProductError:
            return "The operation is already in progress for this product."
        case .unknownBackendError:
            return "There was an unknown backend error."
        case .receiptInUseByOtherSubscriberError:
            return "The receipt is in use by other subscriber."
        case .invalidAppleSubscriptionKeyError:
            return """
                   Apple Subscription Key is invalid or not present. In order to provide subscription offers, you must
                   first generate a subscription key.
                   Please see https://docs.revenuecat.com/docs/ios-subscription-offers for more info.
                   """
        case .ineligibleError:
            return "The User is ineligible for that action."
        case .insufficientPermissionsError:
            return "App does not have sufficient permissions to make purchases"
        case .paymentPendingError:
            return "The payment is pending."
        case .invalidSubscriberAttributesError:
            return "One or more of the attributes sent could not be saved."
        case .logOutAnonymousUserError:
            return "LogOut was called but the current user is anonymous."
        case .configurationError:
            return "There is an issue with your configuration. Check the underlying error for more details."
        case .unsupportedError:
            return """
                   There was a problem with the operation. Looks like we doesn't support that yet.
                   Check the underlying error for more details.
                   """
        case .emptySubscriberAttributes:
            return "A request for subscriber attributes returned none."
        case .productDiscountMissingIdentifierError:
            return "SKProductDiscount must have a non-empty identifier. This is possibly an App Store quirk."
        case .missingAppUserIDForAliasCreationError:
            return "Unable to create an alias when the alias is either nil or empty string"
        case .productDiscountMissingSubscriptionGroupIdentifierError:
            return "Unable to create a discount offer, the product is missing a subscriptionGroupIdentifier."
        @unknown default:
            return "Something went wrong."
        }
    }

}

extension ErrorCode {

    /**
     * The error short string, based on the error code.
     */
    var codeName: String {
        switch self {
        case .networkError:
            return "NETWORK_ERROR"
        case .unknownError:
            return "UNKNOWN"
        case .purchaseCancelledError:
            return "PURCHASE_CANCELLED"
        case .storeProblemError:
            return "STORE_PROBLEM"
        case .purchaseNotAllowedError:
            return "PURCHASE_NOT_ALLOWED"
        case .purchaseInvalidError:
            return "PURCHASE_INVALID"
        case .productNotAvailableForPurchaseError:
            return "PRODUCT_NOT_AVAILABLE_FOR_PURCHASE"
        case .productAlreadyPurchasedError:
            return "PRODUCT_ALREADY_PURCHASED"
        case .receiptAlreadyInUseError:
            return "RECEIPT_ALREADY_IN_USE"
        case .missingReceiptFileError:
            return "MISSING_RECEIPT_FILE"
        case .invalidCredentialsError:
            return "INVALID_CREDENTIALS"
        case .unexpectedBackendResponseError:
            return "UNEXPECTED_BACKEND_RESPONSE_ERROR"
        case .invalidReceiptError:
            return "INVALID_RECEIPT"
        case .invalidAppUserIdError:
            return "INVALID_APP_USER_ID"
        case .operationAlreadyInProgressForProductError:
            return "OPERATION_ALREADY_IN_PROGRESS_FOR_PRODUCT_ERROR"
        case .unknownBackendError:
            return "UNKNOWN_BACKEND_ERROR"
        case .receiptInUseByOtherSubscriberError:
            return "RECEIPT_IN_USE_BY_OTHER_SUBSCRIBER"
        case .invalidAppleSubscriptionKeyError:
            return "INVALID_APPLE_SUBSCRIPTION_KEY"
        case .ineligibleError:
            return "INELIGIBLE_ERROR"
        case .insufficientPermissionsError:
            return "INSUFFICIENT_PERMISSIONS_ERROR"
        case .paymentPendingError:
            return "PAYMENT_PENDING_ERROR"
        case .invalidSubscriberAttributesError:
            return "INVALID_SUBSCRIBER_ATTRIBUTES"
        case .logOutAnonymousUserError:
            return "LOGOUT_CALLED_WITH_ANONYMOUS_USER"
        case .configurationError:
            return "CONFIGURATION_ERROR"
        case .unsupportedError:
            return "UNSUPPORTED_ERROR"
        case .emptySubscriberAttributes:
            return "EMPTY_SUBSCRIBER_ATTRIBUTES"
        case .productDiscountMissingIdentifierError:
            return "PRODUCT_DISCOUNT_MISSING_IDENTIFIER_ERROR"
        case .missingAppUserIDForAliasCreationError:
            return "MISSING_APP_USER_ID_FOR_ALIAS_CREATION_ERROR"
        case .productDiscountMissingSubscriptionGroupIdentifierError:
            return "PRODUCT_DISCOUNT_MISSING_SUBSCRIPTION_GROUP_IDENTIFIER_ERROR"
        @unknown default:
            return "UNRECOGNIZED_ERROR"
        }
    }

}
