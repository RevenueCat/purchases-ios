//
//  RCAttributionFetcher.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

// TODO: remove it when the attribution fetcher will be migrated
typedef void (^RCAttributionDetailsBlock)(NSDictionary<NSString *, NSObject *> *_Nullable, NSError *_Nullable);

@class RCDeviceCache, RCIdentityManager, RCBackend, RCAttributionTypeFactory, RCSystemInfo;


@interface RCAttributionFetcher : NSObject

- (instancetype)initWithDeviceCache:(RCDeviceCache *)deviceCache
                    identityManager:(RCIdentityManager *)identityManager
                            backend:(RCBackend *)backend
                 attributionFactory:(RCAttributionTypeFactory *)attributionFactory
                         systemInfo:(RCSystemInfo *)systemInfo;

- (instancetype)init NS_UNAVAILABLE;

- (nullable NSString *)identifierForAdvertisers;

- (nullable NSString *)identifierForVendor;

- (void)adClientAttributionDetailsWithCompletionBlock:(RCAttributionDetailsBlock)completionHandler;

- (BOOL)isAuthorizedToPostSearchAds;

@end

NS_ASSUME_NONNULL_END
