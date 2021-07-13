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
    RCAttributionPoster,
    RCOfferingsFactory,
    RCDeviceCache,
    RCIdentityManager,
    RCSubscriberAttributesManager,
    RCSystemInfo,
    RCOperationDispatcher,
    RCIntroEligibilityCalculator,
    RCReceiptParser,
    RCPurchaserInfoManager;

#import "RCStoreKitWrapper.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCPurchases (Protected) <RCStoreKitWrapperDelegate>

- (instancetype)initWithAppUserID:(nullable NSString *)appUserID
                   requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                   receiptFetcher:(RCReceiptFetcher *)receiptFetcher
               attributionFetcher:(RCAttributionFetcher *)attributionFetcher
                attributionPoster:(RCAttributionPoster *)attributionPoster
                          backend:(RCBackend *)backend
                  storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
               notificationCenter:(NSNotificationCenter *)notificationCenter
                       systemInfo:(RCSystemInfo *)systemInfo
                 offeringsFactory:(RCOfferingsFactory *)offeringsFactory
                      deviceCache:(RCDeviceCache *)deviceCache
                  identityManager:(RCIdentityManager *)identityManager
      subscriberAttributesManager:(RCSubscriberAttributesManager *)subscriberAttributesManager
              operationDispatcher:(RCOperationDispatcher *)operationDispatcher
       introEligibilityCalculator:(RCIntroEligibilityCalculator *)introEligibilityCalculator
                    receiptParser:(RCReceiptParser *)receiptParser
             purchaserInfoManager:(RCPurchaserInfoManager *)purchaserInfoManager;

+ (void)setDefaultInstance:(nullable RCPurchases *)instance;

- (void)_setPushTokenString:(nullable NSString *)pushToken;

@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) NSNotificationCenter *notificationCenter;

@end


NS_ASSUME_NONNULL_END
