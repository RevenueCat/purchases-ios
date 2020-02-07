//
//  RCDeviceCache.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCDeviceCache.h"
#import "RCDeviceCache+Protected.h"
#import "RCOfferings.h"
#import "RCInMemoryCachedObject.h"
#import "RCInMemoryCachedObject+Protected.h"


@interface RCDeviceCache ()

@property (nonatomic) NSUserDefaults *userDefaults;
@property (nonatomic, nonnull) RCInMemoryCachedObject<RCOfferings *> *offeringsCachedObject;
@property (nonatomic, nullable) NSDate *purchaserInfoCachesLastUpdated;

@end

NSString * RCLegacyGeneratedAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID";
NSString * RCAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID.new";
NSString * RCPurchaserInfoAppUserDefaultsKeyBase = @"com.revenuecat.userdefaults.purchaserInfo.";
#define CACHE_DURATION_IN_SECONDS 60 * 5

@implementation RCDeviceCache

- (instancetype)initWith:(NSUserDefaults *)userDefaults {
    return [self initWith:userDefaults offeringsCachedObject:nil];
}

- (instancetype)initWith:(NSUserDefaults *)userDefaults
   offeringsCachedObject:(RCInMemoryCachedObject<RCOfferings *> *)offeringsCachedObject {
    self = [super init];
    if (self) {
        if (userDefaults == nil) {
            userDefaults = [NSUserDefaults standardUserDefaults];
        }
        self.userDefaults = userDefaults;

        if (offeringsCachedObject == nil) {
            offeringsCachedObject =
                [[RCInMemoryCachedObject alloc] initWithCacheDurationInSeconds:CACHE_DURATION_IN_SECONDS];
        }
        self.offeringsCachedObject = offeringsCachedObject;

    }

    return self;
}

#pragma mark - appUserID

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
    [self clearPurchaserInfoCacheTimestamp];
    [self clearOfferingsCache];
}

#pragma mark - purchaserInfo

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID
{
    return [self.userDefaults dataForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
}

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID
{
    @synchronized(self) {
        [self.userDefaults setObject:data
                              forKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
        [self setPurchaserInfoCacheTimestampToNow];
    }
}

- (BOOL)isPurchaserInfoCacheStale {
    NSTimeInterval timeSinceLastCheck = -[self.purchaserInfoCachesLastUpdated timeIntervalSinceNow];
    return !(self.purchaserInfoCachesLastUpdated != nil && timeSinceLastCheck < CACHE_DURATION_IN_SECONDS);
}

- (void)clearPurchaserInfoCacheTimestamp
{
    self.purchaserInfoCachesLastUpdated = nil;
}

- (void)setPurchaserInfoCacheTimestampToNow
{
    self.purchaserInfoCachesLastUpdated = [NSDate date];
}

#pragma mark - offerings

- (nullable RCOfferings *)cachedOfferings {
    return self.offeringsCachedObject.cachedInstance;
}

- (void)cacheOfferings:(RCOfferings *)offerings
{
    [self.offeringsCachedObject cacheInstance:offerings];
}

- (BOOL)isOfferingsCacheStale {
    return self.offeringsCachedObject.isCacheStale;
}

- (void)clearOfferingsCacheTimestamp
{
    [self.offeringsCachedObject clearCacheTimestamp];
}

- (void)setOfferingsCacheTimestampToNow
{
    [self.offeringsCachedObject updateCacheTimestampWithDate:[NSDate date]];
}

#pragma mark - private methods

- (void)clearOfferingsCache
{
    [self.offeringsCachedObject clearCache];
}

- (NSString *)purchaserInfoUserDefaultCacheKeyForAppUserID:(NSString *)appUserID {
    return [RCPurchaserInfoAppUserDefaultsKeyBase stringByAppendingString:appUserID];
}

@end

