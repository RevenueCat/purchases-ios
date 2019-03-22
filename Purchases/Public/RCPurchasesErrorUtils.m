//
//  RCPurchasesErrorUtils.m
//  Purchases
//
//  Created by César de la Vega  on 3/5/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "RCPurchasesErrors.h"
#import "RCPurchasesErrorUtils.h"
#import "RCUtils.h"

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
    }
    return @"UNRECOGNIZED_ERROR";
}

static RCPurchasesErrorCode RCPurchasesErrorCodeFromRCBackendErrorCode(NSInteger code) {
    switch (code) {
        case RCBackendInvalidPlatform:
            return RCUnknownError;
        case RCBackendStoreProblem:
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
        default:
            return RCUnknownError;
    }
}

static RCPurchasesErrorCode RCPurchasesErrorCodeFromSKError(NSError *skError) {
    if ([[skError domain] isEqualToString:SKErrorDomain]) {
        switch ((SKErrorCode) skError.code) {
            case SKErrorUnknown:
                return RCStoreProblemError;
            case SKErrorClientInvalid:
                return RCPurchaseNotAllowedError;
            case SKErrorPaymentCancelled:
                return RCPurchaseCancelledError;
            case SKErrorPaymentInvalid:
                return RCPurchaseInvalidError;
            case SKErrorPaymentNotAllowed:
                return RCPurchaseNotAllowedError;
            #if !TARGET_OS_MAC
            case SKErrorStoreProductNotAvailable:
                return RCProductNotAvailableForPurchaseError;
            case SKErrorCloudServicePermissionDenied: // Available on iOS 9.3
                return RCPurchaseNotAllowedError;
            case SKErrorCloudServiceNetworkConnectionFailed: // Available on iOS 9.3
                return RCStoreProblemError;
            case SKErrorCloudServiceRevoked: // Available on iOS 10.3
                return RCStoreProblemError;
            #endif
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
                   message:(NSString * _Nullable)message
{
    return [self errorWithCode:code message:message underlyingError:nil];
}


+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
           underlyingError:(NSError * _Nullable)underlyingError
{
    return [self errorWithCode:code message:nil underlyingError:underlyingError extraUserInfo:nil];
}

+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
                   message:(NSString * _Nullable)message
           underlyingError:(NSError * _Nullable)underlyingError
{
    return [self errorWithCode:code message:message underlyingError:underlyingError extraUserInfo:nil];
}

+ (NSError *)errorWithCode:(RCPurchasesErrorCode)code
                   message:(NSString * _Nullable)message
           underlyingError:(NSError * _Nullable)underlyingError
             extraUserInfo:(NSDictionary * _Nullable)extraUserInfo
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

+ (NSError *)backendUnderlyingError:(NSNumber * _Nullable)backendCode
                     backendMessage:(NSString * _Nullable)backendMessage
{

    return [NSError errorWithDomain:RCBackendErrorDomain
                               code:[backendCode integerValue] ?: RCUnknownError
                           userInfo:@{
                                   NSLocalizedDescriptionKey: backendMessage ?: @""
                           }];
}

+ (NSError *)backendErrorWithBackendCode:(NSNumber * _Nullable)backendCode
                          backendMessage:(NSString * _Nullable)backendMessage
{
    return [self backendErrorWithBackendCode:backendCode backendMessage:backendMessage extraUserInfo:nil];
}

+ (NSError *)backendErrorWithBackendCode:(NSNumber * _Nullable)backendCode
                          backendMessage:(NSString * _Nullable)backendMessage
                              finishable:(BOOL)finishable
{
    return [self backendErrorWithBackendCode:backendCode
                              backendMessage:backendMessage
                               extraUserInfo:@{
                                       RCFinishableKey: @(finishable)
                               }];
}

+ (NSError *)backendErrorWithBackendCode:(NSNumber * _Nullable)backendCode
                          backendMessage:(NSString * _Nullable)backendMessage
                           extraUserInfo:(NSDictionary * _Nullable)extraUserInfo
{
    RCPurchasesErrorCode errorCode;
    if (backendCode != nil) {
        errorCode = RCPurchasesErrorCodeFromRCBackendErrorCode([backendCode integerValue]);
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
