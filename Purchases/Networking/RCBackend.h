//
//  RCBackend.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import "RCSubscriberAttribute.h"
#import "RCProductInfo.h"
#import "RCAttributionNetwork.h"


NS_ASSUME_NONNULL_BEGIN

@class RCPurchaserInfo, RCHTTPClient, RCIntroEligibility, RCPromotionalOffer, RCSubscriberAttribute, RCSystemInfo,
        RCETagManager;

extern NSErrorUserInfoKey const RCSuccessfullySyncedKey;
extern NSString * const RCAttributeErrorsKey;
extern NSString * const RCAttributeErrorsResponseKey;

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

typedef void(^IdentifyResponseHandler)(RCPurchaserInfo * _Nullable purchaserInfo,
                                       BOOL created,
                                       NSError * _Nullable error);

@interface RCBackend : NSObject

- (nullable instancetype)initWithAPIKey:(NSString *)APIKey
                             systemInfo:(RCSystemInfo *)systemInfo
                            eTagManager:(RCETagManager *)eTagManager;

- (nullable instancetype)initWithHTTPClient:(RCHTTPClient *)client
                                     APIKey:(NSString *)APIKey;

- (void)    postReceiptData:(NSData *)data
                  appUserID:(NSString *)appUserID
                  isRestore:(BOOL)isRestore
                productInfo:(nullable RCProductInfo *)productInfo
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

- (void)logInWithCurrentAppUserID:(NSString *)currentAppUserID
                     newAppUserID:(NSString *)newAppUserID
                       completion:(void (^)(RCPurchaserInfo * _Nullable purchaserInfo,
                                            BOOL created,
                                            NSError * _Nullable error))completion;

- (void)clearCaches;

@end


NS_ASSUME_NONNULL_END
