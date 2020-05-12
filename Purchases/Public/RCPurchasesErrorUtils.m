//
//  RCPurchasesErrorUtils.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "RCPurchasesErrors.h"
#import "RCPurchasesErrorUtils.h"
#import "RCLogUtils.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Error Domains and UserInfo keys

NSErrorDomain const RCPurchasesErrorDomain = @"RCPurchasesErrorDomain";
NSErrorDomain const RCBackendErrorDomain = @"RCBackendErrorDomain";
NSErrorUserInfoKey const RCFinishableKey = @"finishable";
NSErrorUserInfoKey const RCReadableErrorCodeKey = @"readable_error_code";

#pragma mark - Standard Error Messages

/**
 * The error description, based on the error code.
 * @note No default case so that we get a compiler warning if a new value was added to the enum.
 */
static NSString *RCPurchasesErrorDescription(RCPurchasesErrorCode code) {
    switch (code) {
        case RCNetworkError:
            return @"Error performing request.";
        case RCUnknownError:
            return @"Unknown error.";
        case RCPurchaseCancelledError:
            return @"Purchase was cancelled.";
        case RCStoreProblemError:
            return @"There was a problem with the App Store.";
        case RCPurchaseNotAllowedError:
            return @"The device or user is not allowed to make the purchase.";
        case RCPurchaseInvalidError:
            return @"One or more of the arguments provided are invalid.";
        case RCProductNotAvailableForPurchaseError:
            return @"The product is not available for purchase.";
        case RCProductAlreadyPurchasedError:
            return @"This product is already active for the user.";
        case RCReceiptAlreadyInUseError:
            return @"There is already another active subscriber using the same receipt.";
        case RCMissingReceiptFileError:
            return @"The receipt is missing.";
        case RCInvalidCredentialsError:
            return @"There was a credentials issue. Check the underlying error for more details.";
        case RCUnexpectedBackendResponseError:
            return @"Received malformed response from the backend.";
        case RCInvalidReceiptError:
            return @"The receipt is not valid.";
        case RCInvalidAppUserIdError:
            return @"The app user id is not valid.";
        case RCOperationAlreadyInProgressError:
            return @"The operation is already in progress.";
        case RCUnknownBackendError:
            return @"There was an unknown backend error.";
        case RCReceiptInUseByOtherSubscriberError:
            return @"The receipt is in use by other subscriber.";
        case RCInvalidAppleSubscriptionKeyError:
            return @"Apple Subscription Key is invalid or not present. In order to provide subscription offers, you must first generate a subscription key. Please see https://docs.revenuecat.com/docs/ios-subscription-offers for more info.";
        case RCIneligibleError:
            return @"The User is ineligible for that action.";
        case RCInsufficientPermissionsError:
            return @"App does not have sufficient permissions to make purchases";
        case RCPaymentPendingError:
            return @"The payment is pending.";
        case RCInvalidSubscriberAttributesError:
            return @"One or more of the attributes sent could not be saved.";
    }
    return @"Something went wrong.";
}


/**
 * The error short string, based on the error code.
 * @note No default case so that we get a compiler warning if a new value was added to the enum.
 */
static NSString *const RCPurchasesErrorCodeString(RCPurchasesErrorCode code) {
    switch (code) {
        case RCNetworkError:
            return @"NETWORK_ERROR";
        case RCUnknownError:
            return @"UNKNOWN";
        case RCPurchaseCancelledError:
            return @"PURCHASE_CANCELLED";
        case RCStoreProblemError:
            return @"STORE_PROBLEM";
        case RCPurchaseNotAllowedError:
            return @"PURCHASE_NOT_ALLOWED";
        case RCPurchaseInvalidError:
            return @"PURCHASE_INVALID";
        case RCProductNotAvailableForPurchaseError:
            return @"PRODUCT_NOT_AVAILABLE_FOR_PURCHASE";
        case RCProductAlreadyPurchasedError:
            return @"PRODUCT_ALREADY_PURCHASED";
        case RCReceiptAlreadyInUseError:
            return @"RECEIPT_ALREADY_IN_USE";
        case RCMissingReceiptFileError:
            return @"MISSING_RECEIPT_FILE";
        case RCInvalidCredentialsError:
            return @"INVALID_CREDENTIALS";
        case RCUnexpectedBackendResponseError:
            return @"UNEXPECTED_BACKEND_RESPONSE_ERROR";
        case RCInvalidReceiptError:
            return @"INVALID_RECEIPT";
        case RCInvalidAppUserIdError:
            return @"INVALID_APP_USER_ID";
        case RCOperationAlreadyInProgressError:
            return @"OPERATION_ALREADY_IN_PROGRESS";
        case RCUnknownBackendError:
            return @"UNKNOWN_BACKEND_ERROR";
        case RCReceiptInUseByOtherSubscriberError:
            return @"RECEIPT_IN_USE_BY_OTHER_SUBSCRIBER";
        case RCInvalidAppleSubscriptionKeyError:
            return @"INVALID_APPLE_SUBSCRIPTION_KEY";
        case RCIneligibleError:
            return @"INELIGIBLE_ERROR";
        case RCInsufficientPermissionsError:
            return @"INSUFFICIENT_PERMISSIONS_ERROR";
        case RCPaymentPendingError:
            return @"PAYMENT_PENDING_ERROR";
        case RCInvalidSubscriberAttributesError:
            return @"INVALID_SUBSCRIBER_ATTRIBUTES";
    }
    return @"UNRECOGNIZED_ERROR";
}

static RCPurchasesErrorCode RCPurchasesErrorCodeFromRCBackendErrorCode(RCBackendErrorCode code) {
    switch (code) {
        case RCBackendInvalidPlatform:
            return RCUnknownError;
        case RCBackendStoreProblem:
        case RCBackendPlayStoreQuotaExceeded:
        case RCBackendPlayStoreInvalidPackageName:
        case RCBackendPlayStoreGenericError:
            return RCStoreProblemError;
        case RCBackendCannotTransferPurchase:
            return RCReceiptAlreadyInUseError;
        case RCBackendInvalidReceiptToken:
            return RCInvalidReceiptError;
        case RCBackendInvalidAppStoreSharedSecret:
        case RCBackendInvalidPlayStoreCredentials:
        case RCBackendInvalidAuthToken:
        case RCBackendInvalidAPIKey:
            return RCInvalidCredentialsError;
        case RCBackendInvalidPaymentModeOrIntroPriceNotProvided:
        case RCBackendProductIdForGoogleReceiptNotProvided:
            return RCPurchaseInvalidError;
        case RCBackendEmptyAppUserId:
            return RCInvalidAppUserIdError;
        case RCBackendInvalidAppleSubscriptionKey:
            return RCInvalidAppleSubscriptionKeyError;
        case RCBackendUserIneligibleForPromoOffer:
            return RCIneligibleError;
        case RCBackendInvalidSubscriberAttributes:
        case RCBackendInvalidSubscriberAttributesBody:
            return RCInvalidSubscriberAttributesError;
    }
    return RCUnknownError;
}

#if TARGET_OS_IPHONE
    #define CODE_IF_TARGET_IPHONE(code, value) code
#else
    #define CODE_IF_TARGET_IPHONE(code, value) ((SKErrorCode) value)
#endif

static RCPurchasesErrorCode RCPurchasesErrorCodeFromSKError(NSError *skError) {
    if ([[skError domain] isEqualToString:SKErrorDomain]) {
        switch ((SKErrorCode) skError.code) {
            case SKErrorUnknown:
            case CODE_IF_TARGET_IPHONE(SKErrorCloudServiceNetworkConnectionFailed, 7): // Available on iOS 9.3
            case CODE_IF_TARGET_IPHONE(SKErrorCloudServiceRevoked, 8): // Available on iOS 10.3
                return RCStoreProblemError;
            case SKErrorClientInvalid:
            case SKErrorPaymentNotAllowed:
            case CODE_IF_TARGET_IPHONE(SKErrorCloudServicePermissionDenied, 6): // Available on iOS 9.3
            case SKErrorPrivacyAcknowledgementRequired:
                return RCPurchaseNotAllowedError;
            case SKErrorPaymentCancelled:
                return RCPurchaseCancelledError;
            case SKErrorPaymentInvalid:
            case SKErrorUnauthorizedRequestData:
            case SKErrorMissingOfferParams:
            case SKErrorInvalidOfferPrice:
            case SKErrorInvalidSignature:
            case SKErrorInvalidOfferIdentifier:
                return RCPurchaseInvalidError;
            case CODE_IF_TARGET_IPHONE(SKErrorStoreProductNotAvailable, 5):
                return RCProductNotAvailableForPurchaseError;
        }
    }
    return RCUnknownError;
}

@implementation RCPurchasesErrorUtils

+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
{
    return [self errorWithCode:code message:nil];
}

+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
                   message:(nullable NSString *)message
{
    return [self errorWithCode:code message:message underlyingError:nil];
}


+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
           underlyingError:(nullable NSError *)underlyingError
{
    return [self errorWithCode:code message:nil underlyingError:underlyingError extraUserInfo:nil];
}

+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
                   message:(nullable NSString *)message
           underlyingError:(nullable NSError *)underlyingError
{
    return [self errorWithCode:code message:message underlyingError:underlyingError extraUserInfo:nil];
}

+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
                   message:(nullable NSString *)message
           underlyingError:(nullable NSError *)underlyingError
             extraUserInfo:(nullable NSDictionary *)extraUserInfo
{

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:extraUserInfo];
    userInfo[NSLocalizedDescriptionKey] = message ?: RCPurchasesErrorDescription(code);
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }
    userInfo[RCReadableErrorCodeKey] = RCPurchasesErrorCodeString(code);
    return [self errorWithCode:code userInfo:userInfo];
}

+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
                  userInfo:(NSDictionary *)userInfo
{
    RCErrorLog(@"%@", RCPurchasesErrorDescription(code));
    return [NSError errorWithDomain:RCPurchasesErrorDomain code:code userInfo:userInfo];
}

+ (NSError *)networkErrorWithUnderlyingError:(NSError *)underlyingError
{
    return [self errorWithCode:RCNetworkError
               underlyingError:underlyingError];
}

+ (NSError *)backendUnderlyingError:(nullable NSNumber *)backendCode
                     backendMessage:(nullable NSString *)backendMessage
{

    return [NSError errorWithDomain:RCBackendErrorDomain
                               code:[backendCode integerValue] ?: RCUnknownError
                           userInfo:@{
                                   NSLocalizedDescriptionKey: backendMessage ?: @""
                           }];
}

+ (NSError *)backendErrorWithBackendCode:(nullable NSNumber *)backendCode
                          backendMessage:(nullable NSString *)backendMessage
{
    return [self backendErrorWithBackendCode:backendCode backendMessage:backendMessage extraUserInfo:nil];
}

+ (NSError *)backendErrorWithBackendCode:(nullable NSNumber *)backendCode
                          backendMessage:(nullable NSString *)backendMessage
                              finishable:(BOOL)finishable
{
    return [self backendErrorWithBackendCode:backendCode
                              backendMessage:backendMessage
                               extraUserInfo:@{
                                       RCFinishableKey: @(finishable)
                               }];
}

+ (NSError *)backendErrorWithBackendCode:(nullable NSNumber *)backendCode
                          backendMessage:(nullable NSString *)backendMessage
                           extraUserInfo:(nullable NSDictionary *)extraUserInfo
{
    RCPurchasesErrorCode errorCode;
    if (backendCode != nil) {
        errorCode = RCPurchasesErrorCodeFromRCBackendErrorCode((RCBackendErrorCode) [backendCode integerValue]);
    } else {
        errorCode = RCUnknownBackendError;
    }

    return [self errorWithCode:errorCode
                       message:RCPurchasesErrorDescription(errorCode)
               underlyingError:[self backendUnderlyingError:backendCode backendMessage:backendMessage]
                 extraUserInfo:extraUserInfo];
}

+ (NSError *)unexpectedBackendResponseError
{
    return [self errorWithCode:RCUnexpectedBackendResponseError];
}

+ (NSError *)missingReceiptFileError
{
    return [self errorWithCode:RCMissingReceiptFileError];
}

+ (NSError *)purchasesErrorWithSKError:(NSError *)skError
{

    RCPurchasesErrorCode errorCode = RCPurchasesErrorCodeFromSKError(skError);
    return [self errorWithCode:errorCode
                       message:RCPurchasesErrorDescription(errorCode)
               underlyingError:skError];
}

@end

NS_ASSUME_NONNULL_END
