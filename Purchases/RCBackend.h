//
//  RCBackend.h
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import "RCPurchases.h"

NS_ASSUME_NONNULL_BEGIN

@class RCPurchaserInfo, RCHTTPClient, RCIntroEligibility, RCPromotionalOffer;

typedef NS_ENUM(NSInteger, RCPaymentMode) {
    RCPaymentModeNone = -1,
    RCPaymentModePayAsYouGo = 0,
    RCPaymentModePayUpFront = 1,
    RCPaymentModeFreeTrial = 2
};

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

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey;

- (instancetype _Nullable)initWithHTTPClient:(RCHTTPClient *)client
                                      APIKey:(NSString *)APIKey;

- (void)postReceiptData:(NSData *)data
              appUserID:(NSString *)appUserID
              isRestore:(BOOL)isRestore
      productIdentifier:(NSString * _Nullable)productIdentifier
                  price:(NSDecimalNumber * _Nullable)price
            paymentMode:(RCPaymentMode)paymentMode
      introductoryPrice:(NSDecimalNumber * _Nullable)introductoryPrice
           currencyCode:(NSString * _Nullable)currencyCode
      subscriptionGroup:(NSString * _Nullable)subscriptionGroup
              discounts:(NSArray<RCPromotionalOffer *> * _Nullable)discounts
     presentedOfferingIdentifier:(NSString * _Nullable)offeringIdentifier
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
                 completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

- (void)createAliasForAppUserID:(NSString *)appUserID
               withNewAppUserID:(NSString *)newAppUserID
                     completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

- (void)postOfferForSigning:(NSString *)offerIdentifier
      withProductIdentifier:(NSString *)productIdentifier
          subscriptionGroup:(NSString *)subscriptionGroup
                receiptData:(NSData *)data
                  appUserID:(NSString *)applicationUsername
                 completion:(RCOfferSigningResponseHandler)completion;

@end

NS_ASSUME_NONNULL_END
