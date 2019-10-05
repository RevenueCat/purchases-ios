//
//  RCDeviceCache.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCDeviceCache.h"
#import "RCOfferings.h"

@interface RCDeviceCache ()

@property (nonatomic) NSUserDefaults *userDefaults;

@property (nonatomic) RCOfferings *cachedOfferings;

@end

NSString * RCAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID";
NSString * RCIsAnonymousAppUserDefaultsKey = @"com.revenuecat.userdefaults.isAnonymous";
NSString * RCPurchaserInfoAppUserDefaultsKeyBase = @"com.revenuecat.userdefaults.purchaserInfo.";

@implementation RCDeviceCache

- (instancetype)initWith:(NSUserDefaults *)userDefaults
{
    self = [super init];
    if (self) {
        if (userDefaults == nil) {
            userDefaults = [NSUserDefaults standardUserDefaults];
        }
        self.userDefaults = userDefaults;
    }

    return self;
}

- (nullable NSString *)cachedAppUserID
{
    return [self.userDefaults stringForKey:RCAppUserDefaultsKey];
}

- (void)cacheAppUserID:(NSString *)appUserID isAnonymous:(BOOL)isAnonymous
{
    [self.userDefaults setObject:appUserID forKey:RCAppUserDefaultsKey];
    [self cacheIsAnonymous:isAnonymous];
}

- (void)clearCachesForAppUserID:(NSString *)appUserId
{
    [self clearCachedPurchaserInfoDataForAppUserID:appUserId];
    [self clearCachesTimestamp];
    [self clearOfferings];
}

- (BOOL)isCacheStale {
    NSTimeInterval timeSinceLastCheck = -[self.cachesLastUpdated timeIntervalSinceNow];
    return !(self.cachesLastUpdated != nil && timeSinceLastCheck < 60. * 5);
}

- (void)resetCachesTimestamp
{
    self.cachesLastUpdated = [NSDate date];
}

- (void)clearCachesTimestamp
{
    self.cachesLastUpdated = nil;
}

- (void)cacheOfferings:(RCOfferings *)offerings
{
    self.cachedOfferings = offerings;
}

- (void)clearOfferings
{
    self.cachedOfferings = nil;
}

- (NSString *)purchaserInfoUserDefaultCacheKeyForAppUserID:(NSString *)appUserID {
    return [RCPurchaserInfoAppUserDefaultsKeyBase stringByAppendingString:appUserID];
}

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID
{
    [self.userDefaults setObject:data
                          forKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
}

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID
{
    return [self.userDefaults dataForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
}

- (void)clearCachedPurchaserInfoDataForAppUserID:(NSString *)appUserID
{
    [self.userDefaults removeObjectForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
}

- (BOOL)isAnonymous
{
    NSNumber *isAnonymous = [self.userDefaults objectForKey:RCIsAnonymousAppUserDefaultsKey];
    if (isAnonymous == nil) {
        // It could be an old anonymous user. We default to YES if there is something saved in the other key.
        // Before 3.0 we were only saving anonymous appUserIDs in the cache.
        BOOL isAnOldAnonymousUser = [self.userDefaults stringForKey:RCAppUserDefaultsKey] != nil;
        [self cacheIsAnonymous:isAnOldAnonymousUser];
        return isAnOldAnonymousUser;
    }
    return [isAnonymous boolValue];
}

- (void)cacheIsAnonymous:(BOOL)isAnonymous
{
    [self.userDefaults setBool:isAnonymous forKey:RCIsAnonymousAppUserDefaultsKey];
}

@end

