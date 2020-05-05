//
//  RCDeviceCache.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCDeviceCache.h"
#import "RCDeviceCache+Protected.h"
#import "RCUtils.h"


@interface RCDeviceCache ()

@property (nonatomic) NSUserDefaults *userDefaults;
@property (nonatomic) NSNotificationCenter *notificationCenter;
@property (nonatomic, nonnull) RCInMemoryCachedObject<RCOfferings *> *offeringsCachedObject;
@property (nonatomic, nullable) NSDate *purchaserInfoCachesLastUpdated;

@end


#define RC_CACHE_KEY_PREFIX @"com.revenuecat.userdefaults"

NSString *RCLegacyGeneratedAppUserDefaultsKey = RC_CACHE_KEY_PREFIX @".appUserID";
NSString *RCAppUserDefaultsKey = RC_CACHE_KEY_PREFIX @".appUserID.new";
NSString *RCPurchaserInfoAppUserDefaultsKeyBase = RC_CACHE_KEY_PREFIX @".purchaserInfo.";
NSString *RCLegacySubscriberAttributesKeyBase = RC_CACHE_KEY_PREFIX @".subscriberAttributes.";
NSString *RCSubscriberAttributesKey = RC_CACHE_KEY_PREFIX @".subscriberAttributes";
#define CACHE_DURATION_IN_SECONDS 60 * 5


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
            offeringsCachedObject =
                [[RCInMemoryCachedObject alloc] initWithCacheDurationInSeconds:CACHE_DURATION_IN_SECONDS];
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

- (void)clearCachesForAppUserID:(NSString *)appUserID {
    @synchronized (self) {
        [self.userDefaults removeObjectForKey:RCLegacyGeneratedAppUserDefaultsKey];
        [self.userDefaults removeObjectForKey:RCAppUserDefaultsKey];
        [self.userDefaults removeObjectForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
        [self clearPurchaserInfoCacheTimestamp];
        [self clearOfferingsCache];

        [self deleteAttributesIfSyncedForAppUserID:appUserID];
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

- (NSString *)purchaserInfoUserDefaultCacheKeyForAppUserID:(NSString *)appUserID {
    return [RCPurchaserInfoAppUserDefaultsKeyBase stringByAppendingString:appUserID];
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
        [self.userDefaults setObject:groupedSubscriberAttributes
                              forKey:RCSubscriberAttributesKey];
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
        RCLog(@"found %lu unsynced attributes for appUserID: %@", unsyncedAttributesByKey.count, appUserID);
        if (unsyncedAttributesByKey.count > 0) {
            RCLog(@"unsynced attributes: %@", unsyncedAttributesByKey);
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
        [self.userDefaults setObject:groupedAttributes forKey:RCSubscriberAttributesKey];
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
        NSDictionary *legacyAttributes = ([self valueForLegacySubscriberAttributes:appUserID] ?: @{}).mutableCopy;
        NSMutableDictionary *currentAttributesForAppUserID = (legacyAttributes ?: @{}).mutableCopy;
        NSMutableDictionary *allAttributesForUser = legacyAttributes.mutableCopy;
        [allAttributesForUser addEntriesFromDictionary:currentAttributesForAppUserID];

        attributesInNewFormat[appUserID] = allAttributesForUser;

        NSString *legacyAttributesKey = [self legacySubscriberAttributesCacheKeyForAppUserID:appUserID];
        [self.userDefaults removeObjectForKey:legacyAttributesKey];
    }
    [self.userDefaults setObject:attributesInNewFormat forKey:RCSubscriberAttributesKey];
}

- (void)deleteSyncedSubscriberAttributesForOtherUsers {
    NSDictionary<NSString *, NSDictionary *> *allStoredAttributes = self.storedAttributesForAllUsers;
    NSMutableDictionary<NSString *, NSDictionary *> *unsyncedAttributes = [[NSMutableDictionary alloc] init];

    NSString *currentAppUserID = self.cachedAppUserID;
    NSParameterAssert(currentAppUserID);
    unsyncedAttributes[currentAppUserID] = allStoredAttributes[currentAppUserID];

    for (NSString *appUserID in allStoredAttributes.allKeys) {
        if (![appUserID isEqualToString:currentAppUserID]) {
            NSMutableDictionary *unsyncedAttributesForUser = [[NSMutableDictionary alloc] init];
            for (NSString *attributeKey in allStoredAttributes[appUserID].allKeys) {
                RCSubscriberAttribute *attribute = [[RCSubscriberAttribute alloc]
                                                                           initWithDictionary:allStoredAttributes[appUserID][attributeKey]];
                if (!attribute.isSynced) {
                    unsyncedAttributesForUser[attributeKey] = allStoredAttributes[appUserID][attributeKey];
                }
            }
            if (unsyncedAttributesForUser.count > 0) {
                unsyncedAttributes[appUserID] = unsyncedAttributesForUser;
            }
        }
    }

    [self.userDefaults setObject:unsyncedAttributes forKey:RCSubscriberAttributesKey];
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

@end

