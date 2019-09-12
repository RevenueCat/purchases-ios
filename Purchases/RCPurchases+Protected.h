//
//  RCPurchases+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 10/2/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//


@class RCPurchases, RCStoreKitRequestFetcher, RCBackend, RCStoreKitWrapper, RCReceiptFetcher, RCAttributionFetcher, RCOfferingsFactory;

NS_ASSUME_NONNULL_BEGIN

@interface RCPurchases (Protected)

- (instancetype _Nullable)initWithAppUserID:(NSString * _Nullable)appUserID
                             requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                             receiptFetcher:(RCReceiptFetcher *)receiptFetcher
                         attributionFetcher:(RCAttributionFetcher *)attributionFetcher
                                    backend:(RCBackend *)backend
                            storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
                         notificationCenter:(NSNotificationCenter *)notificationCenter
                               userDefaults:(NSUserDefaults *)userDefaults
                               observerMode:(BOOL)observerMode
                           offeringsFactory:(RCOfferingsFactory *)offeringsFactory;

+ (void)setDefaultInstance:(RCPurchases * _Nullable)instance;

@end

NS_ASSUME_NONNULL_END
