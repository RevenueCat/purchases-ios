//
//  RCPurchasesErrorUtils.h
//  Purchases
//
//  Created by César de la Vega  on 3/5/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class RCPurchasesErrorUtils
 *
 * @brief Utility class used to construct @c NSError instances.
 *
 */
NS_SWIFT_NAME(PurchasesErrorUtils)
@interface RCPurchasesErrorUtils : NSObject

/**
 * @brief Constructs an NSError with the @c RCNetworkError code and a populated @c RCUnderlyingErrorKey in
 * the @c NSError.userInfo dictionary.
 *
 * @param underlyingError The value of the @c NSUnderlyingErrorKey key.
 *
 * @remarks This error is used when there is an error performing network request returns an error or when there
 * is an @c NSJSONSerialization error.
 */
+ (NSError *)networkErrorWithUnderlyingError:(NSError *)underlyingError;

/**
 * @brief Maps an RCBackendError code to a RCPurchasesErrorCode code. Constructs an NSError with the mapped code and adds a
 * @c RCUnderlyingErrorKey in the @c NSError.userInfo dictionary. The backend error code will be mapped using
 * @c [RCPurchasesErrorCodeFromRCBackendErrorCode].
 *
 * @param backendCode The value of the error key.
 * @param backendMessage The value of the @c NSUnderlyingErrorKey key.
 *
 * @remarks This error is used when an network request returns an error. The backend error returned is wrapped in
 * this internal error code.
 */
+ (NSError *)backendErrorWithBackendCode:(NSNumber *_Nullable)backendCode backendMessage:(NSString *_Nullable)backendMessage;


/**
 * @brief Maps an RCBackendError code to a RCPurchasesErrorCode code. Constructs an NSError with the mapped code and adds a
 * @c RCUnderlyingErrorKey in the @c NSError.userInfo dictionary. The backend error code will be mapped using
 * @c [RCPurchasesErrorCodeFromRCBackendErrorCode].
 *
 * @param backendCode The value of the error key.
 * @param backendMessage The value of the @c NSUnderlyingErrorKey key.
 * @param finishable Will be added to the UserInfo dictionary under the @c RCFinishableKey to indicate if the transaction
 * should be finished after this error.
 *
 * @remarks This error is used when an network request returns an error. The backend error returned is wrapped in
 * this internal error code.
 */
+ (NSError *)backendErrorWithBackendCode:(NSNumber *_Nullable)backendCode backendMessage:(NSString *_Nullable)backendMessage finishable:(BOOL)finishable;

/**
 * @brief Constructs an NSError with the @c [RCUnexpectedBackendResponseError] code.
 *
 * @remarks This error is used when an network request returns an unexpected response.
 */
+ (NSError *)unexpectedBackendResponseError;

/**
 * @brief Constructs an NSError with the @c [RCMissingReceiptFileError] code.
 *
 * @remarks This error is used when the receipt is missing in the device. This can happen if the user is in sandbox or
 * if there are no previous purchases.
 */
+ (NSError *)missingReceiptFileError;

/**
 * @brief Maps an SKErrorCode code to a RCPurchasesErrorCode code. Constructs an NSError with the mapped code and adds a
 * @c RCUnderlyingErrorKey in the @c NSError.userInfo dictionary. The SKErrorCode code will be mapped using
 * @c [RCPurchasesErrorCodeFromSKError].
 *
 * @param skError The originating @c [SKError].
 */
+ (NSError *)purchasesErrorWithSKError:(NSError *)skError;
@end

NS_ASSUME_NONNULL_END
