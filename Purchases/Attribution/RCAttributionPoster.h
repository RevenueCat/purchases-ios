//
//  RCAttributionPoster.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2021 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "RCAttributionNetwork.h"

NS_ASSUME_NONNULL_BEGIN

@class RCDeviceCache, RCIdentityManager, RCBackend, RCAttributionData, RCSystemInfo, RCSubscriberAttributesManager,
        RCAttributionFetcher;


@interface RCAttributionPoster : NSObject

- (instancetype)initWithDeviceCache:(RCDeviceCache *)deviceCache
                    identityManager:(RCIdentityManager *)identityManager
                            backend:(RCBackend *)backend
                         systemInfo:(RCSystemInfo *)systemInfo
                 attributionFetcher:(RCAttributionFetcher *)attributionFetcher
        subscriberAttributesManager:(RCSubscriberAttributesManager *)subscriberAttributesManager;

- (instancetype)init NS_UNAVAILABLE;

- (void)postAttributionData:(NSDictionary *)data
                fromNetwork:(RCAttributionNetwork)network
           forNetworkUserId:(nullable NSString *)networkUserId;

- (void)postAppleSearchAdsAttributionIfNeeded;

- (void)postPostponedAttributionDataIfNeeded;

+ (void)storePostponedAttributionData:(NSDictionary *)data
                          fromNetwork:(RCAttributionNetwork)network
                     forNetworkUserId:(nullable NSString *)networkUserId;

@end

NS_ASSUME_NONNULL_END
