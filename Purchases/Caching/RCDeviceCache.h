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

- (BOOL)isPurchaserInfoCacheStale;

- (void)clearPurchaserInfoCacheTimestamp;

- (void)resetPurchaserInfoCache;

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID;

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID;

#pragma mark - offerings

- (BOOL)isOfferingsCacheStale;

- (void)clearOfferingsCacheTimestamp;

- (void)resetOfferingsCache;

- (RCOfferings * _Nullable)cachedOfferings;

- (void)cacheOfferings:(RCOfferings *)offerings;

@end

NS_ASSUME_NONNULL_END
