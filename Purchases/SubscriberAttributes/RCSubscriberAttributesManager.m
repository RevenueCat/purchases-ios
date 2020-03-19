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
        NSParameterAssert(backend);
        NSParameterAssert(deviceCache);
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

- (void)setPushToken:(nullable NSData *)pushToken appUserID:(NSString *)appUserID {
    NSString *pushTokenString = pushToken ? pushToken.asString : nil;
    [self setPushTokenString:pushTokenString appUserID:appUserID];
}

- (void)setPushTokenString:(nullable NSString *)pushTokenString appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PUSH_TOKEN value:pushTokenString appUserID:appUserID];
}

- (void)syncIfNeededWithAppUserID:(NSString *)appUserID completion:(void (^)(NSError *_Nullable error))completion {
    if ([self numberOfUnsyncedAttributesForAppUserID:appUserID] > 0) {
        [self syncAttributesWithCompletion:completion appUserID:appUserID];
    } else {
        completion(nil);
    }
}

- (RCSubscriberAttributeDict)unsyncedAttributesByKeyForAppUserID:(NSString *)appUserID {
    return [self.deviceCache unsyncedAttributesByKeyForAppUserID:appUserID];
}

#pragma MARK - Private methods

- (void)setAttributeWithKey:(nullable NSString *)key value:(NSString *)value appUserID:(NSString *)appUserID {
    [self storeAttributeLocallyIfNeededWithKey:key value:value appUserID:appUserID];
}

- (void)syncAttributesWithCompletion:(void (^)(NSError *_Nullable error))completion appUserID:(NSString *)appUserID {
    RCSubscriberAttributeDict unsyncedAttributes = [self unsyncedAttributesByKeyForAppUserID:appUserID];

    [self.backend postSubscriberAttributes:unsyncedAttributes appUserID:appUserID completion:^(NSError *error) {
        BOOL didBackendReceiveValues = (error == nil || error.successfullySynced);

        if (didBackendReceiveValues) {
            [self markAttributesAsSynced:unsyncedAttributes appUserID:appUserID];
        }
        completion(error);
    }];
}

- (void)markAttributesAsSynced:(RCSubscriberAttributeDict)syncedAttributes
                     appUserID:(NSString *)appUserID {
    if (syncedAttributes == nil || syncedAttributes.count == 0) {
        return;
    }

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

- (void)storeAttributeLocallyIfNeededWithKey:(NSString *)key value:(NSString *)value appUserID:(NSString *)appUserID {
    NSString *valueOrEmpty = value ?: @"";
    NSString * _Nullable currentValue = [self currentValueForAttributeWithKey:key appUserID:appUserID];
    if (!currentValue || ![currentValue isEqualToString:valueOrEmpty]) {
        [self storeAttributeLocallyWithKey:key value:value appUserID:appUserID];
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

- (NSUInteger)numberOfUnsyncedAttributesForAppUserID:(NSString *)appUserID {
    return [self.deviceCache numberOfUnsyncedAttributesForAppUserID:appUserID];
}

@end


NS_ASSUME_NONNULL_END
