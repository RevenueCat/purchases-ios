//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSubscriberAttributesManager.h"
#import "RCSpecialSubscriberAttributes.h"
#import "RCBackend.h"
#import "RCDeviceCache.h"
#import "NSError+RCExtensions.h"
#import "NSData+RCExtensions.h"
#import "RCLogUtils.h"
#import "RCAttributionFetcher.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttributesManager ()

@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCAttributionFetcher *attributionFetcher;

@end


@implementation RCSubscriberAttributesManager

#pragma MARK - Public methods

- (instancetype)initWithBackend:(nullable RCBackend *)backend
                    deviceCache:(nullable RCDeviceCache *)deviceCache
             attributionFetcher:(nullable RCAttributionFetcher *)attributionFetcher{
    if (self = [super init]) {
        NSParameterAssert(backend);
        NSParameterAssert(deviceCache);
        NSParameterAssert(attributionFetcher);
        self.backend = backend;
        self.deviceCache = deviceCache;
        self.attributionFetcher = attributionFetcher;
    }
    return self;
}

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes appUserID:(NSString *)appUserID {
    [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [self setAttributeWithKey:key value:value appUserID:appUserID];
    }];
}

- (void)setEmail:(nullable NSString *)email appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_EMAIL value:email appUserID:appUserID];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PHONE_NUMBER value:phoneNumber appUserID:appUserID];
}

- (void)setDisplayName:(nullable NSString *)displayName appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_DISPLAY_NAME value:displayName appUserID:appUserID];
}

- (void)setPushToken:(nullable NSData *)pushToken appUserID:(NSString *)appUserID {
    NSString *pushTokenString = pushToken ? pushToken.asString : nil;
    [self setPushTokenString:pushTokenString appUserID:appUserID];
}

- (void)setPushTokenString:(nullable NSString *)pushTokenString appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PUSH_TOKEN value:pushTokenString appUserID:appUserID];
}

- (void)setAdjustID:(nullable NSString *)adjustID appUserID:(NSString *)appUserID {
    [self setAttributionID:adjustID networkKey:SPECIAL_ATTRIBUTE_ADJUST_ID appUserID:appUserID];
}

- (void)setAppsflyerID:(nullable NSString *)appsflyerID appUserID:(NSString *)appUserID {
    [self setAttributionID:appsflyerID networkKey:SPECIAL_ATTRIBUTE_APPSFLYER_ID appUserID:appUserID];
}

- (void)setFBAnonymousID:(nullable NSString *)fbAnonymousID appUserID:(NSString *)appUserID {
    [self setAttributionID:fbAnonymousID networkKey:SPECIAL_ATTRIBUTE_FB_ANON_ID appUserID:appUserID];
}

- (void)setMparticleID:(nullable NSString *)mparticleID appUserID:(NSString *)appUserID {
    [self setAttributionID:mparticleID networkKey:SPECIAL_ATTRIBUTE_MPARTICLE_ID appUserID:appUserID];
}

- (void)setOnesignalID:(nullable NSString *)onesignalID appUserID:(NSString *)appUserID {
    [self setAttributionID:onesignalID networkKey:SPECIAL_ATTRIBUTE_ONESIGNAL_ID appUserID:appUserID];
}

- (void)setMediaSource:(nullable NSString *)mediaSource appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_MEDIA_SOURCE value:mediaSource appUserID:appUserID];
}

- (void)setCampaign:(nullable NSString *)campaign appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_CAMPAIGN value:campaign appUserID:appUserID];
}

- (void)setAdGroup:(nullable NSString *)adGroup appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_AD_GROUP value:adGroup appUserID:appUserID];
}

- (void)setAd:(nullable NSString *)ad appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_AD value:ad appUserID:appUserID];
}

- (void)setKeyword:(nullable NSString *)keyword appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_KEYWORD value:keyword appUserID:appUserID];
}

- (void)setCreative:(nullable NSString *)creative appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_CREATIVE value:creative appUserID:appUserID];
}

- (void)collectDeviceIdentifiersForAppUserID:(NSString *)appUserID {
    NSString *identifierForAdvertisers = [self.attributionFetcher identifierForAdvertisers];
    NSString *identifierForVendor = [self.attributionFetcher identifierForVendor];
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_IDFA value:identifierForAdvertisers appUserID:appUserID];
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_IDFV value:identifierForVendor appUserID:appUserID];
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_IP value:@"true" appUserID:appUserID];
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
        RCLog(@"Subscriber attributes synced successfully for appUserID: %@", syncingAppUserID);
        if (syncingAppUserID != currentAppUserID) {
            [self.deviceCache deleteAttributesIfSyncedForAppUserID:syncingAppUserID];
        }
    } else {
        RCErrorLog(@"error when syncing subscriber attributes. Details: %@\n UserInfo:%@",
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
        BOOL didBackendReceiveValues = (error == nil || error.successfullySynced);

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

    RCLog(@"marking the following attributes as synced for appUserID: %@: %@", appUserID, syncedAttributes);
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

@end


NS_ASSUME_NONNULL_END
