//
//  RCBackend.h
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCPurchaserInfo, RCHTTPClient, RCIntroEligibility;

FOUNDATION_EXPORT NSErrorDomain const RCBackendErrorDomain;

NS_ERROR_ENUM(RCBackendErrorDomain) {
    RCFinishableError = 0,
    RCUnfinishableError,
    RCUnexpectedBackendResponse 
};

typedef NS_ENUM(NSInteger, RCPaymentMode) {
    RCPaymentModeNone = -1,
    RCPaymentModePayAsYouGo = 0,
    RCPaymentModePayUpFront = 1,
    RCPaymentModeFreeTrial = 2
};

RCPaymentMode RCPaymentModeFromSKProductDiscountPaymentMode(SKProductDiscountPaymentMode paymentMode);

typedef void(^RCBackendResponseHandler)(RCPurchaserInfo * _Nullable,
                                        NSError * _Nullable);

typedef void(^RCIntroEligibilityResponseHandler)(NSDictionary<NSString *,
                                                 RCIntroEligibility *> *);

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
             completion:(RCBackendResponseHandler)completion;

- (void)getSubscriberDataWithAppUserID:(NSString *)appUserID
                            completion:(RCBackendResponseHandler)completion;

- (void)getIntroElgibilityForAppUserID:(NSString *)appUserID
                           receiptData:(NSData * _Nullable)receiptData
                    productIdentifiers:(NSArray<NSString *> *)productIdentifiers
                            completion:(RCIntroEligibilityResponseHandler)completion;

@end

NS_ASSUME_NONNULL_END
