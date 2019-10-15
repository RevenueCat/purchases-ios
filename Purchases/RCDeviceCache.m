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

NSString * RCLegacyGeneratedAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID";
NSString * RCAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID.new";
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

- (nullable NSString *)cachedLegacyAppUserID
{
    return [self.userDefaults stringForKey:RCLegacyGeneratedAppUserDefaultsKey];
}

- (nullable NSString *)cachedAppUserID
{
    return [self.userDefaults stringForKey:RCAppUserDefaultsKey];
}

- (void)cacheAppUserID:(NSString *)appUserID
{
    [self.userDefaults setObject:appUserID forKey:RCAppUserDefaultsKey];
}

- (void)clearCachesForAppUserID:(NSString *)appUserID
{
    [self.userDefaults removeObjectForKey:RCLegacyGeneratedAppUserDefaultsKey];
    [self.userDefaults removeObjectForKey:RCAppUserDefaultsKey];
    [self.userDefaults removeObjectForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
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

@end

