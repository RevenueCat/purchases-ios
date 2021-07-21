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
//  PurchasesCoreSwift
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
    @objc(RCOperationAlreadyInProgressError) case operationAlreadyInProgressError = 15
    @objc(RCUnknownBackendError) case unknownBackendError = 16
    @objc(RCInvalidAppleSubscriptionKeyError) case invalidAppleSubscriptionKeyError = 17
    @objc(RCIneligibleError) case ineligibleError = 18
    @objc(RCInsufficientPermissionsError) case insufficientPermissionsError = 19
    @objc(RCPaymentPendingError) case paymentPendingError = 20
    @objc(RCInvalidSubscriberAttributesError) case invalidSubscriberAttributesError = 21
    @objc(RCLogOutAnonymousUserError) case logOutAnonymousUserError = 22
    @objc(RCConfigurationError) case configurationError = 23

}
