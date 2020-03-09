//
//  RCBackend.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import "RCPurchases.h"
#import "RCSubscriberAttribute.h"

NS_ASSUME_NONNULL_BEGIN

@class RCPurchaserInfo, RCHTTPClient, RCIntroEligibility, RCPromotionalOffer, RCSubscriberAttribute;

typedef NS_ENUM(NSInteger, RCPaymentMode) {
    RCPaymentModeNone = -1,
    RCPaymentModePayAsYouGo = 0,
    RCPaymentModePayUpFront = 1,
    RCPaymentModeFreeTrial = 2
};

extern NSErrorUserInfoKey const RCSuccessfullySyncedKey;
extern NSString * const RCAttributeErrorsKey;
extern NSString * const RCAttributeErrorsResponseKey;

API_AVAILABLE(ios(11.2), macos(10.13.2))
RCPaymentMode RCPaymentModeFromSKProductDiscountPaymentMode(SKProductDiscountPaymentMode paymentMode);

typedef void(^RCBackendPurchaserInfoResponseHandler)(RCPurchaserInfo * _Nullable,
                                        NSError * _Nullable);

typedef void(^RCIntroEligibilityResponseHandler)(NSDictionary<NSString *,
                                                 RCIntroEligibility *> *);

typedef void(^RCOfferingsResponseHandler)(NSDictionary * _Nullable, NSError * _Nullable);

typedef void(^RCOfferSigningResponseHandler)(NSString * _Nullable signature,
                                             NSString * _Nullable keyIdentifier,
                                             NSUUID * _Nullable nonce,
                                             NSNumber * _Nullable timestamp,
                                             NSError * _Nullable error);

@interface RCBackend : NSObject

- (nullable instancetype)initWithAPIKey:(NSString *)APIKey platformFlavor:(NSString *)platformFlavor;

- (nullable instancetype)initWithHTTPClient:(RCHTTPClient *)client
                                     APIKey:(NSString *)APIKey;

- (void)    postReceiptData:(NSData *)data
                  appUserID:(NSString *)appUserID
                  isRestore:(BOOL)isRestore
          productIdentifier:(nullable NSString *)productIdentifier
                      price:(nullable NSDecimalNumber *)price
                paymentMode:(RCPaymentMode)paymentMode
          introductoryPrice:(nullable NSDecimalNumber *)introductoryPrice
               currencyCode:(nullable NSString *)currencyCode
          subscriptionGroup:(nullable NSString *)subscriptionGroup
                  discounts:(nullable NSArray<RCPromotionalOffer *> *)discounts
presentedOfferingIdentifier:(nullable NSString *)offeringIdentifier
               observerMode:(BOOL)observerMode
       subscriberAttributes:(nullable RCSubscriberAttributeDict)subscriberAttributesByKey
                 completion:(RCBackendPurchaserInfoResponseHandler)completion;

- (void)getSubscriberDataWithAppUserID:(NSString *)appUserID
                            completion:(RCBackendPurchaserInfoResponseHandler)completion;

- (void)getIntroEligibilityForAppUserID:(NSString *)appUserID
                            receiptData:(NSData *)receiptData
                     productIdentifiers:(NSArray<NSString *> *)productIdentifiers
                             completion:(RCIntroEligibilityResponseHandler)completion;

- (void)getOfferingsForAppUserID:(NSString *)appUserID
                      completion:(RCOfferingsResponseHandler)completion;

- (void)postAttributionData:(NSDictionary *)data
                fromNetwork:(RCAttributionNetwork)network
               forAppUserID:(NSString *)appUserID
                 completion:(nullable void (^)(NSError * _Nullable error))completion;

- (void)createAliasForAppUserID:(NSString *)appUserID
               withNewAppUserID:(NSString *)newAppUserID
                     completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

- (void)postOfferForSigning:(NSString *)offerIdentifier
      withProductIdentifier:(NSString *)productIdentifier
          subscriptionGroup:(NSString *)subscriptionGroup
                receiptData:(NSData *)data
                  appUserID:(NSString *)applicationUsername
                 completion:(RCOfferSigningResponseHandler)completion;

- (void)postSubscriberAttributes:(RCSubscriberAttributeDict)subscriberAttributes
                       appUserID:(NSString *)appUserID
                      completion:(nullable void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
