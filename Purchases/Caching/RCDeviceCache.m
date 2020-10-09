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
@property (nonatomic) NSNotificationCenter *notificationCenter;
@property (nonatomic, nonnull) RCInMemoryCachedObject<RCOfferings *> *offeringsCachedObject;

@end


#define RC_CACHE_KEY_PREFIX @"com.revenuecat.userdefaults"

NSString *RCLegacyGeneratedAppUserDefaultsKey = RC_CACHE_KEY_PREFIX @".appUserID";
NSString *RCAppUserDefaultsKey = RC_CACHE_KEY_PREFIX @".appUserID.new";
NSString *RCPurchaserInfoAppUserDefaultsKeyBase = RC_CACHE_KEY_PREFIX @".purchaserInfo.";
NSString *RCPurchaserInfoLastUpdatedKeyBase = RC_CACHE_KEY_PREFIX @".purchaserInfoLastUpdated.";
NSString *RCLegacySubscriberAttributesKeyBase = RC_CACHE_KEY_PREFIX @".subscriberAttributes.";
NSString *RCSubscriberAttributesKey = RC_CACHE_KEY_PREFIX @".subscriberAttributes";
NSString *RCAttributionDataDefaultsKeyBase = RC_CACHE_KEY_PREFIX @".attribution.";
int cacheDurationInSecondsInForeground = 60 * 5;
int cacheDurationInSecondsInBackground = 60 * 60 * 24;

@implementation RCDeviceCache

- (instancetype)initWith:(NSUserDefaults *)userDefaults {
    return [self initWith:userDefaults offeringsCachedObject:nil notificationCenter:nil];
}

- (instancetype)initWith:(NSUserDefaults *)userDefaults
   offeringsCachedObject:(RCInMemoryCachedObject<RCOfferings *> *)offeringsCachedObject
      notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super init];
    if (self) {
        if (offeringsCachedObject == nil) {
            offeringsCachedObject = [[RCInMemoryCachedObject alloc] init];
        }
        self.offeringsCachedObject = offeringsCachedObject;

        if (notificationCenter == nil) {
            notificationCenter = NSNotificationCenter.defaultCenter;
        }
        self.notificationCenter = notificationCenter;

        if (userDefaults == nil) {
            userDefaults = NSUserDefaults.standardUserDefaults;
        }
        self.userDefaults = userDefaults;
        [self observeAppUserIDChanges];
    }

    return self;
}

#pragma mark - UserDefaults Observer

- (void)observeAppUserIDChanges {
    [self.notificationCenter addObserver:self
                                selector:@selector(handleUserDefaultsChanged:)
                                    name:NSUserDefaultsDidChangeNotification
                                  object:self.userDefaults];
}

- (void)handleUserDefaultsChanged:(NSNotification *)notification {
    if (notification.object == self.userDefaults) {
        if (!self.cachedAppUserID) {
            NSAssert(false, @"[Purchases] - Cached appUserID has been deleted from user defaults. "
                            "This leaves the SDK in an undetermined state. Please make sure that RevenueCat "
                            "entries in user defaults don't get deleted by anything other than the SDK. "
                            "More info: https://support.revenuecat.com/hc/en-us/articles/360047927393");
        }
    }
}

- (void)dealloc {
    [self.notificationCenter removeObserver:self];
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

- (void)clearCachesForAppUserID:(NSString *)oldAppUserID andSaveNewUserID:(NSString *)newUserID {
    @synchronized (self) {
        [self.userDefaults removeObjectForKey:RCLegacyGeneratedAppUserDefaultsKey];
        [self.userDefaults removeObjectForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:oldAppUserID]];
        [self clearPurchaserInfoCacheTimestampForAppUserID:oldAppUserID];
        [self clearOfferingsCache];

        [self deleteAttributesIfSyncedForAppUserID:oldAppUserID];

        [self cacheAppUserID:newUserID];
    }
}

#pragma mark - purchaserInfo

- (nullable NSData *)cachedPurchaserInfoDataForAppUserID:(NSString *)appUserID {
    return [self.userDefaults dataForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
}

- (void)cachePurchaserInfo:(NSData *)data forAppUserID:(NSString *)appUserID {
    @synchronized (self) {
        [self.userDefaults setObject:data
                              forKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
        [self setPurchaserInfoCacheTimestampToNowForAppUserID:appUserID];
    }
}

- (BOOL)isPurchaserInfoCacheStaleForAppUserID:(NSString *)appUserID isAppBackgrounded:(BOOL)isAppBackgrounded {
    NSDate * _Nullable purchaserInfoCachesLastUpdated = [self purchaserInfoCachesLastUpdatedForAppUserID:appUserID];
    if (!purchaserInfoCachesLastUpdated) {
        return YES;
    }
    NSTimeInterval timeSinceLastCheck = -[purchaserInfoCachesLastUpdated timeIntervalSinceNow];
    int cacheDurationInSeconds = [self cacheDurationInSecondsWithIsAppBackgrounded:isAppBackgrounded];
    return timeSinceLastCheck >= cacheDurationInSeconds;
}

- (int)cacheDurationInSecondsWithIsAppBackgrounded:(BOOL)isAppBackgrounded {
    return (isAppBackgrounded ? cacheDurationInSecondsInBackground
                              : cacheDurationInSecondsInForeground);
}

- (void)clearPurchaserInfoCacheTimestampForAppUserID:(NSString *)appUserID {
    NSString *cacheKey = [self purchaserInfoLastUpdatedCacheKeyForAppUserID:appUserID];
    [self.userDefaults removeObjectForKey:cacheKey];
}

- (void)clearPurchaserInfoCacheForAppUserID:(NSString *)appUserID {
    @synchronized (self) {
        [self clearPurchaserInfoCacheTimestampForAppUserID:appUserID];
        [self.userDefaults removeObjectForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
    }
}

- (void)setPurchaserInfoCacheTimestampToNowForAppUserID:(NSString *)appUserID {
    [self setPurchaserInfoCacheTimestamp:[NSDate date] forAppUserID:appUserID];
}

- (void)setPurchaserInfoCacheTimestamp:(NSDate *)timestamp forAppUserID:(NSString *)appUserID {
    NSString *cacheKey = [self purchaserInfoLastUpdatedCacheKeyForAppUserID:appUserID];
    [self.userDefaults setObject:timestamp forKey:cacheKey];
}

- (nullable NSDate *)purchaserInfoCachesLastUpdatedForAppUserID:(NSString *)appUserID {
    NSString *cacheKey = [self purchaserInfoLastUpdatedCacheKeyForAppUserID:appUserID];
    return (NSDate * _Nullable) [self.userDefaults objectForKey:cacheKey];
}

- (NSString *)purchaserInfoUserDefaultCacheKeyForAppUserID:(NSString *)appUserID {
    return [RCPurchaserInfoAppUserDefaultsKeyBase stringByAppendingString:appUserID];
}

- (NSString *)purchaserInfoLastUpdatedCacheKeyForAppUserID:(NSString *)appUserID {
    return [RCPurchaserInfoLastUpdatedKeyBase stringByAppendingString:appUserID];
}

#pragma mark - offerings

- (nullable RCOfferings *)cachedOfferings {
    return self.offeringsCachedObject.cachedInstance;
}

- (void)cacheOfferings:(RCOfferings *)offerings {
    [self.offeringsCachedObject cacheInstance:offerings];
}

- (BOOL)isOfferingsCacheStaleWithIsAppBackgrounded:(BOOL)isAppBackgrounded {
    int cacheDurationInSeconds = [self cacheDurationInSecondsWithIsAppBackgrounded:isAppBackgrounded];
    return [self.offeringsCachedObject isCacheStaleWithDurationInSeconds:cacheDurationInSeconds];
}

- (void)clearOfferingsCacheTimestamp {
    [self.offeringsCachedObject clearCacheTimestamp];
}

- (void)setOfferingsCacheTimestampToNow {
    [self.offeringsCachedObject updateCacheTimestampWithDate:[NSDate date]];
}

- (void)clearOfferingsCache {
    [self.offeringsCachedObject clearCache];
}

#pragma mark - subscriber attributes

- (void)storeSubscriberAttribute:(RCSubscriberAttribute *)attribute
                       appUserID:(NSString *)appUserID {
    [self storeSubscriberAttributes:@{attribute.key: attribute}
                          appUserID:appUserID];
}

- (void)storeSubscriberAttributes:(RCSubscriberAttributeDict)attributesByKey
                        appUserID:(NSString *)appUserID {
    if (attributesByKey.count == 0) {
        return;
    }

    @synchronized (self) {
        NSMutableDictionary *groupedSubscriberAttributes = self.storedAttributesForAllUsers.mutableCopy;
        NSMutableDictionary
            *subscriberAttributesForAppUserID = ((NSDictionary *) groupedSubscriberAttributes[appUserID] ?: @{})
            .mutableCopy;

        for (NSString *key in attributesByKey) {
            subscriberAttributesForAppUserID[key] = attributesByKey[key].asDictionary;
        }

        groupedSubscriberAttributes[appUserID] = subscriberAttributesForAppUserID;
        [self storeAttributesForAllUsers:groupedSubscriberAttributes];
    }
}

- (NSDictionary *)subscriberAttributesForAppUserID:(NSString *)appUserID {
    return self.storedAttributesForAllUsers[appUserID] ?: @{};
}

- (nullable RCSubscriberAttribute *)subscriberAttributeWithKey:(NSString *)attributeKey
                                                     appUserID:(NSString *)appUserID {
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
        *allAttributesObjectsByKey = [self subscriberAttributesForAppUserID:appUserID];
    RCSubscriberAttributeMutableDict allSubscriberAttributesByKey = [[NSMutableDictionary alloc] init];

    for (NSString *key in allAttributesObjectsByKey) {
        NSDictionary <NSString *, NSString *> *attributeAsDict =
            (NSDictionary <NSString *, NSString *> *) allAttributesObjectsByKey[key];
        allSubscriberAttributesByKey[key] = [[RCSubscriberAttribute alloc]
                                                                    initWithDictionary:attributeAsDict];
    }
    return allSubscriberAttributesByKey;
}

- (NSUInteger)numberOfUnsyncedAttributesForAppUserID:(NSString *)appUserID {
    return [self unsyncedAttributesByKeyForAppUserID:appUserID].count;
}

- (NSDictionary<NSString *, NSDictionary *> *)storedAttributesForAllUsers {
    return [self.userDefaults dictionaryForKey:RCSubscriberAttributesKey] ?: @{};
}

- (void)storeAttributesForAllUsers:(NSMutableDictionary<NSString *, NSDictionary *> *)groupedAttributes {
    [self.userDefaults setObject:groupedAttributes forKey:RCSubscriberAttributesKey];
}

- (NSDictionary<NSString *, RCSubscriberAttributeDict> *)unsyncedAttributesForAllUsers {
    NSDictionary *attributesDict = self.storedAttributesForAllUsers;
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];

    for (NSString *appUserID in attributesDict.allKeys) {
        NSDictionary *attributesDictForUser = (NSDictionary *) attributesDict[appUserID];
        NSMutableDictionary *attributesForUser = [[NSMutableDictionary alloc] init];

        for (NSString *attributeKey in attributesDictForUser.allKeys) {
            NSDictionary *attributeDict = (NSDictionary *) attributesDictForUser[attributeKey];
            RCSubscriberAttribute *attribute = [[RCSubscriberAttribute alloc] initWithDictionary:attributeDict];
            if (!attribute.isSynced) {
                attributesForUser[attributeKey] = attribute;
            }
        }
        if (attributesForUser.count > 0) {
            attributes[appUserID] = attributesForUser;
        }
    }
    return attributes;
}

- (void)deleteAttributesIfSyncedForAppUserID:(NSString *)appUserID {
    @synchronized (self) {
        if ([self numberOfUnsyncedAttributesForAppUserID:appUserID] != 0) {
            return;
        }
        NSMutableDictionary <NSString *, NSDictionary *>
            *groupedAttributes = self.storedAttributesForAllUsers.mutableCopy;
        [groupedAttributes removeObjectForKey:appUserID];
        [self storeAttributesForAllUsers:groupedAttributes];
    }
}

# pragma mark - subscriber attributes migration from per-user key to grouped key

- (void)cleanupSubscriberAttributes {
    @synchronized (self) {
        [self migrateSubscriberAttributes];
        [self deleteSyncedSubscriberAttributesForOtherUsers];
    }
}

- (void)migrateSubscriberAttributes {
    NSArray *appUserIDsWithLegacyAttributes = [self appUserIDsWithLegacyAttributes];
    NSMutableDictionary *attributesInNewFormat = self.storedAttributesForAllUsers.mutableCopy;
    for (NSString *appUserID in appUserIDsWithLegacyAttributes) {
        NSDictionary *legacyAttributes = [self valueForLegacySubscriberAttributes:appUserID] ?: @{};
        NSDictionary *existingAttributes = self.storedAttributesForAllUsers[appUserID] ?: @{};

        NSMutableDictionary *allAttributesForUser = legacyAttributes.mutableCopy;
        [allAttributesForUser addEntriesFromDictionary:existingAttributes];

        attributesInNewFormat[appUserID] = allAttributesForUser;

        NSString *legacyAttributesKey = [self legacySubscriberAttributesCacheKeyForAppUserID:appUserID];
        [self.userDefaults removeObjectForKey:legacyAttributesKey];
    }
    [self storeAttributesForAllUsers:attributesInNewFormat];
}

- (void)deleteSyncedSubscriberAttributesForOtherUsers {
    NSDictionary<NSString *, NSDictionary *> *allStoredAttributes = self.storedAttributesForAllUsers;
    NSMutableDictionary<NSString *, NSDictionary *> *filteredAttributes = [[NSMutableDictionary alloc] init];

    NSString *currentAppUserID = self.cachedAppUserID;
    NSParameterAssert(currentAppUserID);
    filteredAttributes[currentAppUserID] = allStoredAttributes[currentAppUserID];

    for (NSString *appUserID in allStoredAttributes.allKeys) {
        if (![appUserID isEqualToString:currentAppUserID]) {
            NSMutableDictionary *unsyncedAttributesForUser = [[NSMutableDictionary alloc] init];
            for (NSString *attributeKey in allStoredAttributes[appUserID].allKeys) {
                NSDictionary<NSString *, NSObject *>
                    *storedAttributesForUser = allStoredAttributes[appUserID][attributeKey];

                RCSubscriberAttribute *attribute = [[RCSubscriberAttribute alloc]
                                                                           initWithDictionary:storedAttributesForUser];
                if (!attribute.isSynced) {
                    unsyncedAttributesForUser[attributeKey] = storedAttributesForUser;
                }
            }
            if (unsyncedAttributesForUser.count > 0) {
                filteredAttributes[appUserID] = unsyncedAttributesForUser;
            }
        }
    }

    [self storeAttributesForAllUsers:filteredAttributes];
}

- (NSArray<NSString *> *)appUserIDsWithLegacyAttributes {
    NSMutableArray *appUserIDsWithLegacyAttributes = [[NSMutableArray alloc] init];
    NSDictionary *userDefaultsDict = [self.userDefaults dictionaryRepresentation];
    for (NSString *key in userDefaultsDict.allKeys) {
        if ([key containsString:RCLegacySubscriberAttributesKeyBase]) {
            NSString *appUserID = [key stringByReplacingOccurrencesOfString:RCLegacySubscriberAttributesKeyBase
                                                                 withString:@""];
            [appUserIDsWithLegacyAttributes addObject:appUserID];
        }
    }
    return appUserIDsWithLegacyAttributes;
}

- (nullable NSDictionary *)valueForLegacySubscriberAttributes:(NSString *)appUserID {
    return [self.userDefaults dictionaryForKey:[self legacySubscriberAttributesCacheKeyForAppUserID:appUserID]];
}

- (NSString *)legacySubscriberAttributesCacheKeyForAppUserID:(NSString *)appUserID {
    NSString *attributeKey = [NSString stringWithFormat:@"%@", appUserID];
    return [RCLegacySubscriberAttributesKeyBase stringByAppendingString:attributeKey];
}

#pragma mark - attribution

- (nullable NSDictionary *)latestNetworkAndAdvertisingIdsSentForAppUserID:(NSString *)appUserID {
    NSString *cacheKey = [self attributionDataCacheKeyForAppForAppUserID:appUserID];
    return [self.userDefaults objectForKey:cacheKey];
}

- (void)setLatestNetworkAndAdvertisingIdsSent:(nullable NSDictionary *)latestNetworkAndAdvertisingIdsSent
                                 forAppUserID:(nullable NSString *)appUserID {
    NSString *cacheKey = [self attributionDataCacheKeyForAppForAppUserID:appUserID];
    [self.userDefaults setObject:latestNetworkAndAdvertisingIdsSent
                          forKey:cacheKey];
}

- (void)clearLatestNetworkAndAdvertisingIdsSentForAppUserID:(nullable NSString *)appUserID {
    NSString *cacheKey = [self attributionDataCacheKeyForAppForAppUserID:appUserID];
    [self.userDefaults removeObjectForKey:cacheKey];
}

- (NSString *)attributionDataCacheKeyForAppForAppUserID:(NSString *)appUserID {
    return [RCAttributionDataDefaultsKeyBase stringByAppendingString:appUserID];
}

@end

