//
//  RCDeviceCache.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCOfferings;

NS_ASSUME_NONNULL_BEGIN

@interface RCDeviceCache : NSObject

@property (nonatomic, readonly, nullable) NSString *cachedAppUserID;

@property (nonatomic, readonly, nullable) NSString *cachedLegacyAppUserID;

@property (nonatomic, readonly, nullable) RCOfferings *cachedOfferings;

@property (nonatomic, nullable) NSDate *cachesLastUpdated;

- (instancetype)initWith:(NSUserDefaults *)userDefaults;

- (void)cacheAppUserID:(NSString *)appUserID;

- (void)clearCachesForAppUserID:(NSString *)appUserID;

- (BOOL)isCacheStale;

- (BOOL)isOfferingsCacheStale;

- (void)resetCachesTimestamp;

- (void)clearCachesTimestamp;

- (void)cacheOfferings:(RCOfferings *)offerings;

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID;

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID;

@end

NS_ASSUME_NONNULL_END
