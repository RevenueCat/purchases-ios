//
//  RCPurchases+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//


@class RCPurchases, RCStoreKitRequestFetcher, RCBackend, RCStoreKitWrapper, RCReceiptFetcher, RCAttributionFetcher, RCOfferingsFactory, RCDeviceCache, RCUserIdentity;

NS_ASSUME_NONNULL_BEGIN

@interface RCPurchases (Protected)

- (instancetype)initWithAppUserID:(nullable NSString *)appUserID
                   requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                   receiptFetcher:(RCReceiptFetcher *)receiptFetcher
               attributionFetcher:(RCAttributionFetcher *)attributionFetcher
                          backend:(RCBackend *)backend
                  storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
               notificationCenter:(NSNotificationCenter *)notificationCenter
                     userDefaults:(NSUserDefaults *)userDefaults
                     observerMode:(BOOL)observerMode
                 offeringsFactory:(RCOfferingsFactory *)offeringsFactory
                      deviceCache:(RCDeviceCache *)cache
                     userIdentity:(RCUserIdentity *)userIdentity;

+ (void)setDefaultInstance:(nullable RCPurchases *)instance;

@end

NS_ASSUME_NONNULL_END
