//
//  RCDeviceCache.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSubscriberAttribute.h"

@class RCOfferings;

NS_ASSUME_NONNULL_BEGIN

@interface RCDeviceCache : NSObject

- (instancetype)initWith:(NSUserDefaults *)userDefaults;

#pragma mark - appUserID

@property (nonatomic, readonly, nullable) NSString *cachedAppUserID;

@property (nonatomic, readonly, nullable) NSString *cachedLegacyAppUserID;

- (void)cacheAppUserID:(NSString *)appUserID;

- (void)clearCachesForAppUserID:(NSString *)oldAppUserID andSaveNewUserID:(NSString *)newUserID;

#pragma mark - purchaserInfo

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID;

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID;

- (BOOL)isPurchaserInfoCacheStaleForAppUserID:(NSString *)appUserID isAppBackgrounded:(BOOL)isAppBackgrounded;

- (void)clearPurchaserInfoCacheTimestampForAppUserID:(NSString *)appUserID;

- (void)clearPurchaserInfoCacheForAppUserID:(NSString *)appUserID;

- (void)setPurchaserInfoCacheTimestampToNowForAppUserID:(NSString *)appUserID;

#pragma mark - offerings

@property (nonatomic, readonly, nullable) RCOfferings *cachedOfferings;

- (void)cacheOfferings:(RCOfferings *)offerings;

- (BOOL)isOfferingsCacheStaleWithIsAppBackgrounded:(BOOL)isAppBackgrounded;

- (void)clearOfferingsCacheTimestamp;

- (void)setOfferingsCacheTimestampToNow;

#pragma mark - subscriber attributes

- (void)storeSubscriberAttribute:(RCSubscriberAttribute *)attribute appUserID:(NSString *)appUserID;

- (void)storeSubscriberAttributes:(RCSubscriberAttributeDict)attributesByKey
                        appUserID:(NSString *)appUserID;

- (nullable RCSubscriberAttribute *)subscriberAttributeWithKey:(NSString *)attributeKey appUserID:(NSString *)appUserID;

- (RCSubscriberAttributeDict)unsyncedAttributesByKeyForAppUserID:(NSString *)appUserID;

- (NSUInteger)numberOfUnsyncedAttributesForAppUserID:(NSString *)appUserID;

- (void)cleanupSubscriberAttributes;

- (NSDictionary<NSString *, RCSubscriberAttributeDict> *)unsyncedAttributesForAllUsers;

- (void)deleteAttributesIfSyncedForAppUserID:(NSString *)appUserID;

#pragma mark - attribution

- (nullable NSDictionary *)latestNetworkAndAdvertisingIdsSentForAppUserID:(NSString *)appUserID;

- (void)setLatestNetworkAndAdvertisingIdsSent:(nullable NSDictionary *)latestNetworkAndAdvertisingIdsSent
                                 forAppUserID:(nullable NSString *)appUserID;

- (void)clearLatestNetworkAndAdvertisingIdsSentForAppUserID:(nullable NSString *)appUserID;

@end

NS_ASSUME_NONNULL_END
