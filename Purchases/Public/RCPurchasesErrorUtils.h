//
//  RCPurchasesErrorUtils.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class used to construct [NSError] instances.
 */
NS_SWIFT_NAME(Purchases.ErrorUtils)
@interface RCPurchasesErrorUtils : NSObject

/**
 * Constructs an NSError with the [RCNetworkError] code and a populated [RCUnderlyingErrorKey] in
 * the [NSError.userInfo] dictionary.
 *
 * @param underlyingError The value of the [NSUnderlyingErrorKey] key.
 *
 * @note This error is used when there is an error performing network request returns an error or when there
 * is an [NSJSONSerialization] error.
 */
+ (NSError *)networkErrorWithUnderlyingError:(NSError *)underlyingError;

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
+ (NSError *)backendErrorWithBackendCode:(nullable NSNumber *)backendCode backendMessage:(nullable NSString *)backendMessage;

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
+ (NSError *)backendErrorWithBackendCode:(nullable NSNumber *)backendCode backendMessage:(nullable NSString *)backendMessage finishable:(BOOL)finishable;

/**
 * Constructs an NSError with the [RCUnexpectedBackendResponseError] code.
 *
 * @note This error is used when an network request returns an unexpected response.
 */
+ (NSError *)unexpectedBackendResponseError;

/**
 * Constructs an NSError with the [RCMissingReceiptFileError] code.
 *
 * @note This error is used when the receipt is missing in the device. This can happen if the user is in sandbox or
 * if there are no previous purchases.
 */
+ (NSError *)missingReceiptFileError;

/**
 * Constructs an NSError with the [RCInvalidAppUserIdError] code.
 *
 * @note This error is used when the appUserID can't be found in user defaults. This can happen if user defaults
 * are removed manually or if the OS deletes entries when running out of space.
 */
+ (NSError *)missingAppUserIDError;

/**
 * Constructs an NSError with the [RCLogOutAnonymousUserError] code.
 *
 * @note This error is used when logOut is called but the current user is anonymous,
 * as noted by RCPurchaserInfo's isAnonymous property.
 */
+ (NSError *)logOutAnonymousUserError;

/**
 * Constructs an NSError with the [RCPaymentPendingError] code.
 *
 * @note This error is used during an “ask to buy” flow for a payment. The completion block of the purchasing function
 * will get this error to indicate the guardian has to complete the purchase.
 */
+ (NSError *)paymentDeferredError;

/**
 * Constructs an NSError with the [RCUnknownError] code.
 */
+ (NSError *)unknownError;

/**
 * Maps an SKErrorCode code to a RCPurchasesErrorCode code. Constructs an NSError with the mapped code and adds a
 * [RCUnderlyingErrorKey] in the NSError.userInfo dictionary. The SKErrorCode code will be mapped using
 * [RCPurchasesErrorCodeFromSKError].
 *
 * @param skError The originating [SKError].
 */
+ (NSError *)purchasesErrorWithSKError:(NSError *)skError;

@end

NS_ASSUME_NONNULL_END
