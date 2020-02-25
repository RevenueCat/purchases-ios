//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSubscriberAttributesManager.h"
#import "RCSubscriberAttribute.h"
#import "RCSpecialSubscriberAttributes.h"
#import "RCBackend.h"
#import "RCDeviceCache.h"
#import "NSError+RCExtensions.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttributesManager ()

@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCBackend *backend;

@end


@implementation RCSubscriberAttributesManager

#pragma MARK - Public methods

- (instancetype)initWithBackend:(nullable RCBackend *)backend
                    deviceCache:(nullable RCDeviceCache *)deviceCache {
    if (self = [super init]) {
        self.backend = backend;
        self.deviceCache = deviceCache;
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

- (void)setPushToken:(nullable NSString *)pushToken appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PUSH_TOKEN value:pushToken appUserID:appUserID];
}

- (void)syncIfNeededWithAppUserID:(NSString *)appUserID completion:(void (^)(NSError *_Nullable error))completion {
    if ([self numberOfUnsyncedAttributesForAppUserID:appUserID] > 0) {
        [self syncAttributesWithCompletion:completion appUserID:appUserID];
    } else {
        completion(nil);
    }
}

- (NSDictionary <NSString *, RCSubscriberAttribute *> *)unsyncedAttributesByKeyForAppUserID:(NSString *)appUserID {
    return [self.deviceCache unsyncedAttributesByKeyForAppUserID:appUserID];
}

- (void)clearAttributesForAppUserID:(NSString *)appUserID {
    [self.deviceCache clearSubscriberAttributesForAppUserID:appUserID];
}

#pragma MARK - Private methods

- (void)setAttributeWithKey:(nullable NSString *)key value:(NSString *)value appUserID:(NSString *)appUserID {
    [self storeAttributeLocallyIfNeededWithKey:key value:value appUserID:appUserID];
}

- (void)syncAttributesWithCompletion:(void (^)(NSError *_Nullable error))completion appUserID:(NSString *)appUserID {
    NSDictionary <NSString *, RCSubscriberAttribute *>
        *unsyncedAttributes = [self unsyncedAttributesByKeyForAppUserID:appUserID];

    [self.backend postSubscriberAttributes:unsyncedAttributes appUserID:appUserID completion:^(NSError *error) {
        BOOL didBackendReceiveValues = (error == nil || error.isBackendError);

        if (didBackendReceiveValues) {
            [self markAttributesAsSynced:unsyncedAttributes appUserID:appUserID];
        }
        completion(error);
    }];
}

- (void)markAttributesAsSynced:(NSDictionary <NSString *, RCSubscriberAttribute *> *)syncedAttributes
                     appUserID:(NSString *)appUserID {
    NSMutableDictionary <NSString *, RCSubscriberAttribute *> *unsyncedAttributes =
        [self unsyncedAttributesByKeyForAppUserID:appUserID].mutableCopy;

    for (NSString *key in syncedAttributes) {
        RCSubscriberAttribute *attribute = [unsyncedAttributes valueForKey:key];
        if (attribute != nil && [attribute.value isEqualToString:syncedAttributes[key].value]) {
            attribute.isSynced = YES;
            unsyncedAttributes[key] = attribute;
        }
    }
    [self.deviceCache storeSubscriberAttributes:unsyncedAttributes appUserID:appUserID];
}

- (void)storeAttributeLocallyIfNeededWithKey:(NSString *)key value:(NSString *)value appUserID:(NSString *)appUserID {
    NSString *valueOrEmpty = value ?: @"";
    if (![[self currentValueForAttributeWithKey:key appUserID:appUserID] isEqualToString:valueOrEmpty]) {
        [self storeAttributeLocallyWithKey:key value:value appUserID:appUserID];
    }
}

- (void)storeAttributeLocallyWithKey:(NSString *)key value:(NSString *)value appUserID:(NSString *)appUserID {
    if ([self currentValueForAttributeWithKey:key appUserID:appUserID] != value) {
        RCSubscriberAttribute *subscriberAttribute = [[RCSubscriberAttribute alloc] initWithKey:key
                                                                                          value:value
                                                                                      appUserID:appUserID];
        [self.deviceCache storeSubscriberAttribute:subscriberAttribute];
    }
}

- (NSString *)currentValueForAttributeWithKey:(NSString *)key appUserID:(NSString *)appUserID {
    RCSubscriberAttribute *attribute = [self.deviceCache subscriberAttributeWithKey:key appUserID:appUserID];
    return attribute.value;
}

- (NSUInteger)numberOfUnsyncedAttributesForAppUserID:(NSString *)appUserID {
    return [self.deviceCache numberOfUnsyncedAttributesForAppUserID:appUserID];
}

@end


NS_ASSUME_NONNULL_END
