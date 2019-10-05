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

@property (nonatomic, readonly, nullable) RCOfferings *cachedOfferings;

@property (nonatomic, nullable) NSDate *cachesLastUpdated;

- (instancetype)initWith:(NSUserDefaults *)userDefaults;

- (void)cacheAppUserID:(NSString *)appUserID isAnonymous:(BOOL)isAnonymous;

- (void)clearCachesForAppUserID:(NSString *)appUserId;

- (BOOL)isCacheStale;

- (void)resetCachesTimestamp;

- (void)clearCachesTimestamp;

- (void)cacheOfferings:(RCOfferings *)offerings;

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID;

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID;

- (BOOL)isAnonymous;

@end

NS_ASSUME_NONNULL_END
