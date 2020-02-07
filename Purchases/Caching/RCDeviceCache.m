//
//  RCDeviceCache.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCDeviceCache.h"
#import "RCOfferings.h"
#import "RCInMemoryCachedObject.h"


@interface RCDeviceCache ()

@property (nonatomic) NSUserDefaults *userDefaults;
@property (nonatomic, nonnull) RCInMemoryCachedObject<RCOfferings *> *offeringsCachedObject;

@end

NSString * RCLegacyGeneratedAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID";
NSString * RCAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID.new";
NSString * RCPurchaserInfoAppUserDefaultsKeyBase = @"com.revenuecat.userdefaults.purchaserInfo.";
#define CACHE_DURATION_IN_SECONDS 60 * 5

@implementation RCDeviceCache

- (instancetype)initWith:(NSUserDefaults *)userDefaults
{
    self = [super init];
    if (self) {
        if (userDefaults == nil) {
            userDefaults = [NSUserDefaults standardUserDefaults];
        }
        self.userDefaults = userDefaults;

        self.offeringsCachedObject = [[RCInMemoryCachedObject alloc] initWithCacheDurationInSeconds:CACHE_DURATION_IN_SECONDS];
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
    return !(self.cachesLastUpdated != nil && timeSinceLastCheck < CACHE_DURATION_IN_SECONDS);
}

- (BOOL)isOfferingsCacheStale {
    return self.offeringsCachedObject.isCacheStale;
}

- (RCOfferings * _Nullable)cachedOfferings {
    return self.offeringsCachedObject.cachedInstance;
}

- (void)resetCachesTimestamp
{
    NSDate *now = [NSDate date];
    self.cachesLastUpdated = now;
    [self.offeringsCachedObject updateCacheTimestampWithDate:now];
}

- (void)clearCachesTimestamp
{
    self.cachesLastUpdated = nil;
    [self.offeringsCachedObject clearCacheTimestamp];
}

- (void)cacheOfferings:(RCOfferings *)offerings
{
    [self.offeringsCachedObject cacheInstance:offerings date:[NSDate date]];
}

- (void)clearOfferings
{
    [self.offeringsCachedObject clearCache];
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

