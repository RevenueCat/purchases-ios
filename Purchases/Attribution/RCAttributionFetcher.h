//
//  RCAttributionFetcher.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "RCAttributionTypeFactory.h"

NS_ASSUME_NONNULL_BEGIN

@class RCDeviceCache, RCIdentityManager, RCBackend, RCSystemInfo;


@interface RCAttributionFetcher : NSObject

- (instancetype)initWithDeviceCache:(RCDeviceCache *)deviceCache
                    identityManager:(RCIdentityManager *)identityManager
                            backend:(RCBackend *)backend
                 attributionFactory:(RCAttributionTypeFactory *)attributionFactory
                         systemInfo:(RCSystemInfo *)systemInfo;

- (instancetype)init NS_UNAVAILABLE;

- (nullable NSString *)identifierForAdvertisers;

- (nullable NSString *)identifierForVendor;

- (void)afficheClientAttributionDetailsWithCompletionBlock:(RCAttributionDetailsBlock)completionHandler;

- (BOOL)isAuthorizedToPostSearchAds;

@end

NS_ASSUME_NONNULL_END
