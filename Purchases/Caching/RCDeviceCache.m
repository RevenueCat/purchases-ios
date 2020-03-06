//
//  RCDeviceCache.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCDeviceCache.h"
#import "RCDeviceCache+Protected.h"


@interface RCDeviceCache ()

@property (nonatomic) NSUserDefaults *userDefaults;
@property (nonatomic, nonnull) RCInMemoryCachedObject<RCOfferings *> *offeringsCachedObject;
@property (nonatomic, nullable) NSDate *purchaserInfoCachesLastUpdated;

@end


#define RC_CACHE_KEY_PREFIX @"com.revenuecat.userdefaults"

NSString *RCLegacyGeneratedAppUserDefaultsKey = RC_CACHE_KEY_PREFIX @".appUserID";
NSString *RCAppUserDefaultsKey = RC_CACHE_KEY_PREFIX @".appUserID.new";
NSString *RCPurchaserInfoAppUserDefaultsKeyBase = RC_CACHE_KEY_PREFIX @".purchaserInfo.";
NSString *RCSubscriberAttributesKeyBase = RC_CACHE_KEY_PREFIX @".subscriberAttributes.";
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

- (nullable NSString *)cachedLegacyAppUserID {
    return [self.userDefaults stringForKey:RCLegacyGeneratedAppUserDefaultsKey];
}

- (nullable NSString *)cachedAppUserID {
    return [self.userDefaults stringForKey:RCAppUserDefaultsKey];
}

- (void)cacheAppUserID:(NSString *)appUserID {
    [self.userDefaults setObject:appUserID forKey:RCAppUserDefaultsKey];
}

- (void)clearCachesForAppUserID:(NSString *)appUserID {
    [self.userDefaults removeObjectForKey:RCLegacyGeneratedAppUserDefaultsKey];
    [self.userDefaults removeObjectForKey:RCAppUserDefaultsKey];
    [self.userDefaults removeObjectForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
    [self.userDefaults removeObjectForKey:[self subscriberAttributesCacheKeyForAppUserID:appUserID]];
    [self clearPurchaserInfoCacheTimestamp];
    [self clearOfferingsCache];
}

#pragma mark - purchaserInfo

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID {
    return [self.userDefaults dataForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
}

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID {
    @synchronized (self) {
        [self.userDefaults setObject:data
                              forKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
        [self setPurchaserInfoCacheTimestampToNow];
    }
}

- (BOOL)isPurchaserInfoCacheStale {
    NSTimeInterval timeSinceLastCheck = -[self.purchaserInfoCachesLastUpdated timeIntervalSinceNow];
    return !(self.purchaserInfoCachesLastUpdated != nil && timeSinceLastCheck < CACHE_DURATION_IN_SECONDS);
}

- (void)clearPurchaserInfoCacheTimestamp {
    self.purchaserInfoCachesLastUpdated = nil;
}

- (void)setPurchaserInfoCacheTimestampToNow {
    self.purchaserInfoCachesLastUpdated = [NSDate date];
}

#pragma mark - offerings

- (nullable RCOfferings *)cachedOfferings {
    return self.offeringsCachedObject.cachedInstance;
}

- (void)cacheOfferings:(RCOfferings *)offerings {
    [self.offeringsCachedObject cacheInstance:offerings];
}

- (BOOL)isOfferingsCacheStale {
    return self.offeringsCachedObject.isCacheStale;
}

- (void)clearOfferingsCacheTimestamp {
    [self.offeringsCachedObject clearCacheTimestamp];
}

- (void)setOfferingsCacheTimestampToNow {
    [self.offeringsCachedObject updateCacheTimestampWithDate:[NSDate date]];
}

#pragma mark - Subscriber attributes

- (void)storeSubscriberAttribute:(RCSubscriberAttribute *)attribute appUserID:(NSString *)appUserID {
    @synchronized (self) {
        NSString *cacheKey = [self subscriberAttributesCacheKeyForAppUserID:appUserID];
        NSDictionary *allSubscriberAttributesByKey = (NSDictionary *) [self.userDefaults valueForKey:cacheKey];
        NSMutableDictionary *mutableSubscriberAttributesByKey = allSubscriberAttributesByKey
                                                                ? allSubscriberAttributesByKey.mutableCopy
                                                                : [[NSMutableDictionary alloc] init];

        mutableSubscriberAttributesByKey[attribute.key] = attribute.asDictionary;
        [self.userDefaults setObject:mutableSubscriberAttributesByKey
                              forKey:cacheKey];
    }
}

- (void)storeSubscriberAttributes:(RCSubscriberAttributeDict)attributesByKey
                        appUserID:(NSString *)appUserID {
    if (attributesByKey.count == 0) {
        return;
    }

    @synchronized (self) {
        NSString *cacheKey = [self subscriberAttributesCacheKeyForAppUserID:appUserID];
        NSDictionary <NSString *, NSObject *>
            *allSubscriberAttributesByKey = [self storedSubscriberAttributesDictionaryForAppUserID:appUserID];
        NSMutableDictionary *mutableSubscriberAttributesByKey = allSubscriberAttributesByKey
                                                                ? allSubscriberAttributesByKey.mutableCopy
                                                                : [[NSMutableDictionary alloc] init];
        for (NSString *key in attributesByKey) {
            mutableSubscriberAttributesByKey[key] = [attributesByKey[key] asDictionary];
        }
        [self.userDefaults setObject:mutableSubscriberAttributesByKey
                              forKey:cacheKey];
    }
}

- (nullable RCSubscriberAttribute *)subscriberAttributeWithKey:(NSString *)attributeKey appUserID:(NSString *)appUserID {
    @synchronized (self) {
        RCSubscriberAttributeDict
            allSubscriberAttributesByKey = [self storedSubscriberAttributesForAppUserID:appUserID];
        return allSubscriberAttributesByKey[attributeKey];
    }
}

- (RCSubscriberAttributeDict)unsyncedAttributesByKeyForAppUserID:(NSString *)appUserID {
    @synchronized (self) {
        RCSubscriberAttributeDict
            allSubscriberAttributesByKey = [self storedSubscriberAttributesForAppUserID:appUserID];
        RCSubscriberAttributeMutableDict unsyncedAttributesByKey = [[NSMutableDictionary alloc] init];
        for (NSString *key in allSubscriberAttributesByKey) {
            RCSubscriberAttribute *attribute = allSubscriberAttributesByKey[key];
            if (!attribute.isSynced) {
                unsyncedAttributesByKey[attribute.key] = attribute;
            }
        }
        return unsyncedAttributesByKey;
    }
}

- (RCSubscriberAttributeDict)storedSubscriberAttributesForAppUserID:(NSString *)appUserID {
    NSDictionary <NSString *, NSObject *>
        *allAttributesObjectsByKey = [self storedSubscriberAttributesDictionaryForAppUserID:appUserID];
    RCSubscriberAttributeMutableDict allSubscriberAttributesByKey =
        [[NSMutableDictionary alloc] init];

    for (NSString *key in allAttributesObjectsByKey) {
        NSDictionary <NSString *, NSString *> *attributeAsDict =
            (NSDictionary <NSString *, NSString *> *) allAttributesObjectsByKey[key];
        allSubscriberAttributesByKey[key] = [[RCSubscriberAttribute alloc]
                                                                    initWithDictionary:attributeAsDict];
    }
    return allSubscriberAttributesByKey;
}

- (NSDictionary <NSString *, NSObject *> *)storedSubscriberAttributesDictionaryForAppUserID:(NSString *)appUserID {
    NSString *cacheKey = [self subscriberAttributesCacheKeyForAppUserID:appUserID];
    NSDictionary *allAttributesObjectsByKey = [self.userDefaults valueForKey:cacheKey];
    return allAttributesObjectsByKey;
}

- (NSUInteger)numberOfUnsyncedAttributesForAppUserID:(NSString *)appUserID {
    return [self unsyncedAttributesByKeyForAppUserID:appUserID].count;
}

- (NSString *)subscriberAttributesCacheKeyForAppUserID:(NSString *)appUserID {
    NSString *attributeKey = [NSString stringWithFormat:@"%@", appUserID];
    return [RCSubscriberAttributesKeyBase stringByAppendingString:attributeKey];
}

#pragma mark - private methods

- (void)clearOfferingsCache {
    [self.offeringsCachedObject clearCache];
}

- (NSString *)purchaserInfoUserDefaultCacheKeyForAppUserID:(NSString *)appUserID {
    return [RCPurchaserInfoAppUserDefaultsKeyBase stringByAppendingString:appUserID];
}

@end

