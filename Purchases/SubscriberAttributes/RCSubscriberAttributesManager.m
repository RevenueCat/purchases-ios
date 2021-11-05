//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSubscriberAttributesManager.h"
#import "RCBackend.h"
#import "RCDeviceCache.h"
#import "NSError+RCExtensions.h"
#import "NSData+RCExtensions.h"
#import "RCLogUtils.h"
#import "RCAttributionFetcher.h"
@import PurchasesCoreSwift;

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttributesManager ()

@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCAttributionFetcher *attributionFetcher;
@property (nonatomic) RCAttributionDataMigrator *attributionDataMigrator;

@end


@implementation RCSubscriberAttributesManager

#pragma MARK - Public methods

- (instancetype)initWithBackend:(nullable RCBackend *)backend
                    deviceCache:(nullable RCDeviceCache *)deviceCache
             attributionFetcher:(nullable RCAttributionFetcher *)attributionFetcher
        attributionDataMigrator:(nullable RCAttributionDataMigrator *)attributionDataMigrator {
    if (self = [super init]) {
        NSParameterAssert(backend);
        NSParameterAssert(deviceCache);
        NSParameterAssert(attributionFetcher);
        NSParameterAssert(attributionDataMigrator);
        self.backend = backend;
        self.deviceCache = deviceCache;
        self.attributionFetcher = attributionFetcher;
        self.attributionDataMigrator = attributionDataMigrator;
    }
    return self;
}

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes appUserID:(NSString *)appUserID {
    [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [self setAttributeWithKey:key value:value appUserID:appUserID];
    }];
}

- (void)setEmail:(nullable NSString *)email appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.email value:email appUserID:appUserID];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.phoneNumber value:phoneNumber appUserID:appUserID];
}

- (void)setDisplayName:(nullable NSString *)displayName appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.displayName value:displayName appUserID:appUserID];
}

- (void)setPushToken:(nullable NSData *)pushToken appUserID:(NSString *)appUserID {
    NSString *pushTokenString = pushToken ? pushToken.rc_asString : nil;
    [self setPushTokenString:pushTokenString appUserID:appUserID];
}

- (void)setPushTokenString:(nullable NSString *)pushTokenString appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.pushToken value:pushTokenString appUserID:appUserID];
}

- (void)setAdjustID:(nullable NSString *)adjustID appUserID:(NSString *)appUserID {
    [self setAttributionID:adjustID networkKey:RCSpecialSubscriberAttributes.adjustID appUserID:appUserID];
}

- (void)setAppsflyerID:(nullable NSString *)appsflyerID appUserID:(NSString *)appUserID {
    [self setAttributionID:appsflyerID networkKey:RCSpecialSubscriberAttributes.appsFlyerID appUserID:appUserID];
}

- (void)setFBAnonymousID:(nullable NSString *)fbAnonymousID appUserID:(NSString *)appUserID {
    [self setAttributionID:fbAnonymousID networkKey:RCSpecialSubscriberAttributes.fBAnonID appUserID:appUserID];
}

- (void)setMparticleID:(nullable NSString *)mparticleID appUserID:(NSString *)appUserID {
    [self setAttributionID:mparticleID networkKey:RCSpecialSubscriberAttributes.mpParticleID appUserID:appUserID];
}

- (void)setOnesignalID:(nullable NSString *)onesignalID appUserID:(NSString *)appUserID {
    [self setAttributionID:onesignalID networkKey:RCSpecialSubscriberAttributes.oneSignalID appUserID:appUserID];
}

- (void)setAirshipChannelID:(nullable NSString *)airshipChannelID appUserID:(NSString *)appUserID {
    [self setAttributionID:airshipChannelID
                networkKey:RCSpecialSubscriberAttributes.airshipChannelID
                 appUserID:appUserID];
}

- (void)setMediaSource:(nullable NSString *)mediaSource appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.mediaSource value:mediaSource appUserID:appUserID];
}

- (void)setCampaign:(nullable NSString *)campaign appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.campaign value:campaign appUserID:appUserID];
}

- (void)setAdGroup:(nullable NSString *)adGroup appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.adGroup value:adGroup appUserID:appUserID];
}

- (void)setAd:(nullable NSString *)ad appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.ad value:ad appUserID:appUserID];
}

- (void)setKeyword:(nullable NSString *)keyword appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.keyword value:keyword appUserID:appUserID];
}

- (void)setCreative:(nullable NSString *)creative appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.creative value:creative appUserID:appUserID];
}

- (void)collectDeviceIdentifiersForAppUserID:(NSString *)appUserID {
    NSString *identifierForAdvertisers = [self.attributionFetcher identifierForAdvertisers];
    NSString *identifierForVendor = [self.attributionFetcher identifierForVendor];
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.idfa value:identifierForAdvertisers appUserID:appUserID];
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.idfv value:identifierForVendor appUserID:appUserID];
    [self setAttributeWithKey:RCSpecialSubscriberAttributes.ip value:@"true" appUserID:appUserID];
}

- (void)syncAttributesForAllUsersWithCurrentAppUserID:(NSString *)currentAppUserID {
    NSDictionary <NSString *, RCSubscriberAttributeDict> *unsyncedAttributesForAllUsers =
        [self unsyncedAttributesByKeyForAllUsers];

    for (NSString *syncingAppUserID in unsyncedAttributesForAllUsers.allKeys) {
        [self syncAttributes:unsyncedAttributesForAllUsers[syncingAppUserID]
                forAppUserID:syncingAppUserID
                  completion:^(NSError *error) {
                      [self handleAttributesSyncedForAppUserID:syncingAppUserID
                                              currentAppUserID:currentAppUserID
                                                         error:error];
                  }];
    }
}

- (void)handleAttributesSyncedForAppUserID:(NSString *)syncingAppUserID
                          currentAppUserID:(NSString *)currentAppUserID
                                     error:(NSError *)error {
    if (error == nil) {
        RCSuccessLog(RCStrings.attribution.attributes_sync_success, syncingAppUserID);
        if (![syncingAppUserID isEqualToString:currentAppUserID]) {
            [self.deviceCache deleteAttributesIfSyncedForAppUserID:syncingAppUserID];
        }
    } else {
        RCErrorLog(RCStrings.attribution.attributes_sync_error,
                   error.localizedDescription,
                   error.userInfo);
    }
}

- (RCSubscriberAttributeDict)unsyncedAttributesByKeyForAppUserID:(NSString *)appUserID {
    return [self.deviceCache unsyncedAttributesByKeyForAppUserID:appUserID];
}

- (NSDictionary <NSString *, RCSubscriberAttributeDict> *)unsyncedAttributesByKeyForAllUsers {
    return [self.deviceCache unsyncedAttributesForAllUsers];
}

#pragma MARK - Private methods

- (void)setAttributeWithKey:(NSString *)key value:(nullable NSString *)value appUserID:(NSString *)appUserID {
    [self storeAttributeLocallyIfNeededWithKey:key value:value appUserID:appUserID];
}

- (void)syncAttributes:(RCSubscriberAttributeDict)attributes
          forAppUserID:(NSString *)appUserID
            completion:(void (^)(NSError *))completion {
    [self.backend postSubscriberAttributes:attributes appUserID:appUserID completion:^(NSError *error) {
        BOOL didBackendReceiveValues = (error == nil || error.rc_successfullySynced);

        if (didBackendReceiveValues) {
            [self markAttributesAsSynced:attributes appUserID:appUserID];
        }
        completion(error);
    }];
}

- (void)markAttributesAsSynced:(RCSubscriberAttributeDict)syncedAttributes
                     appUserID:(NSString *)appUserID {
    if (syncedAttributes == nil || syncedAttributes.count == 0) {
        return;
    }

    RCLog(RCStrings.attribution.marking_attributes_synced, appUserID, syncedAttributes);
    @synchronized (self) {
        RCSubscriberAttributeMutableDict
            unsyncedAttributes = [self unsyncedAttributesByKeyForAppUserID:appUserID].mutableCopy;

        for (NSString *key in syncedAttributes) {
            RCSubscriberAttribute *attribute = [unsyncedAttributes valueForKey:key];
            if (attribute != nil && [attribute.value isEqualToString:syncedAttributes[key].value]) {
                attribute.isSynced = YES;
                unsyncedAttributes[key] = attribute;
            }
        }
        [self.deviceCache storeSubscriberAttributes:unsyncedAttributes appUserID:appUserID];
    }
}

- (void)storeAttributeLocallyIfNeededWithKey:(NSString *)key
                                       value:(nullable NSString *)value
                                   appUserID:(NSString *)appUserID {
    NSString *valueOrEmpty = value ?: @"";
    NSString *_Nullable currentValue = [self currentValueForAttributeWithKey:key appUserID:appUserID];
    if (!currentValue || ![currentValue isEqualToString:valueOrEmpty]) {
        [self storeAttributeLocallyWithKey:key value:valueOrEmpty appUserID:appUserID];
    }
}

- (void)storeAttributeLocallyWithKey:(NSString *)key value:(NSString *)value appUserID:(NSString *)appUserID {
    RCSubscriberAttribute *subscriberAttribute = [[RCSubscriberAttribute alloc] initWithKey:key
                                                                                      value:value];
    [self.deviceCache storeSubscriberAttribute:subscriberAttribute appUserID:appUserID];
}

- (nullable NSString *)currentValueForAttributeWithKey:(NSString *)key appUserID:(NSString *)appUserID {
    RCSubscriberAttribute *attribute = [self.deviceCache subscriberAttributeWithKey:key appUserID:appUserID];
    return attribute ? attribute.value : nil;
}

- (void)setAttributionID:(nullable NSString *)networkID
              networkKey:(NSString *)networkKey
               appUserID:(NSString *)appUserID {
    [self collectDeviceIdentifiersForAppUserID:appUserID];
    [self setAttributeWithKey:networkKey value:networkID appUserID:appUserID];
}

- (void)convertAttributionDataAndSetAsSubscriberAttributes:(NSDictionary *)attributionData
                                                   network:(RCAttributionNetwork)network
                                                 appUserID:(NSString *)appUserID {
    NSDictionary *convertedAttribution =
                        [self.attributionDataMigrator convertToSubscriberAttributesWithAttributionData:attributionData
                                                                                               network:network];
    [self setAttributes:convertedAttribution appUserID:appUserID];
}

@end


NS_ASSUME_NONNULL_END
