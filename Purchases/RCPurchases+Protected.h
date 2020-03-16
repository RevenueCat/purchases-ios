//
//  RCPurchases+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//


@class RCPurchases,
    RCStoreKitRequestFetcher,
    RCBackend,
    RCStoreKitWrapper,
    RCReceiptFetcher,
    RCAttributionFetcher,
    RCOfferingsFactory,
    RCDeviceCache,
    RCIdentityManager,
    RCSubscriberAttributesManager;

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
                      deviceCache:(RCDeviceCache *)deviceCache
                  identityManager:(RCIdentityManager *)identityManager
      subscriberAttributesManager:(RCSubscriberAttributesManager *)subscriberAttributesManager;

+ (void)setDefaultInstance:(nullable RCPurchases *)instance;

@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) NSNotificationCenter *notificationCenter;

@end


NS_ASSUME_NONNULL_END
