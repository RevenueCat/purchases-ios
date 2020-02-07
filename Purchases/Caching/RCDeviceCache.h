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

- (instancetype)initWith:(NSUserDefaults *)userDefaults;

#pragma mark - appUserID

@property (nonatomic, readonly, nullable) NSString *cachedAppUserID;

@property (nonatomic, readonly, nullable) NSString *cachedLegacyAppUserID;

- (void)cacheAppUserID:(NSString *)appUserID;

- (void)clearCachesForAppUserID:(NSString *)appUserID;

#pragma mark - purchaserInfo

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID;

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID;

- (BOOL)isPurchaserInfoCacheStale;

- (void)clearPurchaserInfoCacheTimestamp;

- (void)setPurchaserInfoCacheTimestampToNow;

#pragma mark - offerings

@property (nonatomic, readonly, nullable) RCOfferings *cachedOfferings;

- (void)cacheOfferings:(RCOfferings *)offerings;

- (BOOL)isOfferingsCacheStale;

- (void)clearOfferingsCacheTimestamp;

- (void)setOfferingsCacheTimestampToNow;

@end

NS_ASSUME_NONNULL_END
