//
//  RCPurchasesErrors.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_SWIFT_NAME(Purchases.Errors)
@interface RCPurchasesErrors

/**
 `NSErrorDomain` for errors occurring within the scope of the Purchases SDK.
 */
extern NSErrorDomain const RCPurchasesErrorDomain NS_SWIFT_NAME(Purchases.ErrorDomain);

/**
 `NSErrorDomain` for errors occurring within the scope of the RevenueCat Backend.
 */
extern NSErrorDomain const RCBackendErrorDomain NS_SWIFT_NAME(Purchases.RevenueCatBackendErrorDomain);

extern NSErrorUserInfoKey const RCFinishableKey NS_SWIFT_NAME(Purchases.FinishableKey);

extern NSErrorUserInfoKey const RCReadableErrorCodeKey NS_SWIFT_NAME(Purchases.ReadableErrorCodeKey);


/**
 Error codes used by the Purchases SDK
 */
typedef NS_ERROR_ENUM(RCPurchasesErrorDomain, RCPurchasesErrorCode) {
    RCUnknownError = 0,
    RCPurchaseCancelledError,
    RCStoreProblemError,
    RCPurchaseNotAllowedError,
    RCPurchaseInvalidError,
    RCProductNotAvailableForPurchaseError,
    RCProductAlreadyPurchasedError,
    RCReceiptAlreadyInUseError,
    RCInvalidReceiptError,
    RCMissingReceiptFileError,
    RCNetworkError,
    RCInvalidCredentialsError,
    RCUnexpectedBackendResponseError,
    RCReceiptInUseByOtherSubscriberError,
    RCInvalidAppUserIdError,
    RCOperationAlreadyInProgressError,
    RCUnknownBackendError,
    RCInvalidAppleSubscriptionKeyError,
    RCIneligibleError,
    RCInsufficientPermissionsError,
    RCPaymentPendingError,
    RCInvalidSubscriberAttributesError,
} NS_SWIFT_NAME(Purchases.ErrorCode);

/**
 Error codes sent by the RevenueCat backend. This only includes the errors that matter to the SDK
 */
typedef NS_ENUM(NSInteger, RCBackendErrorCode) {
    RCBackendInvalidPlatform = 7000,
    RCBackendStoreProblem = 7101,
    RCBackendCannotTransferPurchase = 7102,
    RCBackendInvalidReceiptToken = 7103,
    RCBackendInvalidAppStoreSharedSecret = 7104,
    RCBackendInvalidPaymentModeOrIntroPriceNotProvided = 7105,
    RCBackendProductIdForGoogleReceiptNotProvided = 7106,
    RCBackendInvalidPlayStoreCredentials = 7107,
    RCBackendEmptyAppUserId = 7220,
    RCBackendInvalidAuthToken = 7224,
    RCBackendInvalidAPIKey = 7225,
    RCBackendPlayStoreQuotaExceeded = 7229,
    RCBackendPlayStoreInvalidPackageName = 7230,
    RCBackendPlayStoreGenericError = 7231,
    RCBackendUserIneligibleForPromoOffer = 7232,
    RCBackendInvalidAppleSubscriptionKey = 7234,
    RCBackendInvalidSubscriberAttributes = 7263,
    RCBackendInvalidSubscriberAttributesBody = 7264
} NS_SWIFT_NAME(Purchases.RevenueCatBackendErrorCode);

@end
