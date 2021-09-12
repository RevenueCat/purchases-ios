//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorCodesAPI.swift
//
//  Created by Madeline Beyl on 9/5/21.

import Foundation
import RevenueCat

var backendErrCode: BackendErrorCode!
func checkErrorCodeEnums() {
    switch backendErrCode! {
    case .invalidPlatform,
         .storeProblem,
         .cannotTransferPurchase,
         .invalidReceiptToken,
         .invalidAppStoreSharedSecret,
         .invalidPaymentModeOrIntroPriceNotProvided,
         .productIdForGoogleReceiptNotProvided,
         .invalidPlayStoreCredentials,
         .internalServerError,
         .emptyAppUserId,
         .invalidAuthToken,
         .invalidAPIKey,
         .badRequest,
         .playStoreQuotaExceeded,
         .playStoreInvalidPackageName,
         .playStoreGenericError,
         .userIneligibleForPromoOffer,
         .invalidAppleSubscriptionKey,
         .invalidSubscriberAttributes,
         .invalidSubscriberAttributesBody,
         .unknownError:
        print(backendErrCode!)
    }
}

var errCode: ErrorCode!
func checkPurchasesErrorCodeEnums() {
    switch errCode! {
    case .unknownError,
         .purchaseCancelledError,
         .storeProblemError,
         .purchaseNotAllowedError,
         .purchaseInvalidError,
         .productNotAvailableForPurchaseError,
         .productAlreadyPurchasedError,
         .receiptAlreadyInUseError,
         .invalidReceiptError,
         .missingReceiptFileError,
         .networkError,
         .invalidCredentialsError,
         .unexpectedBackendResponseError,
         .receiptInUseByOtherSubscriberError,
         .invalidAppUserIdError,
         .unknownBackendError,
         .invalidAppleSubscriptionKeyError,
         .ineligibleError,
         .insufficientPermissionsError,
         .paymentPendingError,
         .invalidSubscriberAttributesError,
         .logOutAnonymousUserError,
         .configurationError,
         .operationAlreadyInProgressForProductError,
         .emptySubscriberAttributes,
         .productDiscountMissingIdentifierError,
         .missingAppUserIDForAliasCreationError,
         .productDiscountMissingSubscriptionGroupIdentifierError:
        print(errCode!)
    }
}
