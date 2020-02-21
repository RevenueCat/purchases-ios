//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSubscriberAttributesManager.h"
#import "RCSubscriberAttribute.h"
#import "RCSpecialSubscriberAttributes.h"
#import "RCBackend.h"
#import "RCDeviceCache.h"

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
        [self setAttributeWithKey:key value:value];
    }];
}

- (void)setEmail:(nullable NSString *)email appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_EMAIL value:email];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PHONE_NUMBER value:phoneNumber];
}

- (void)setDisplayName:(nullable NSString *)displayName appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_DISPLAY_NAME value:displayName];
}

- (void)setPushToken:(nullable NSString *)pushToken appUserID:(NSString *)appUserID {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PUSH_TOKEN value:pushToken];
}

- (void)syncIfNeededWithAppUserID:(NSString *)appUserID completion:(void (^)(NSError *_Nullable error))completion {
    if (self.numberOfUnsyncedAttributes > 0) {
        [self syncAttributesWithCompletion:completion appUserID:appUserID];
    } else {
        completion(nil);
    }
}

- (NSArray <RCSubscriberAttribute *> *)unsyncedAttributesForAppUserID:(NSString *)appUserID {
    return [self.deviceCache unsyncedAttributesForAppUserID:appUserID];
}

- (void)clearAttributesForAppUserID:(NSString *)appUserID {
    [self.deviceCache clearSubscriberAttributesForAppUserID:appUserID];
}

#pragma MARK - Private methods

- (void)setAttributeWithKey:(nullable NSString *)key value:(NSString *)value {
    [self storeAttributeLocallyIfNeededWithKey:key value:value];
}

- (void)syncAttributesWithCompletion:(void (^)(NSError *_Nullable error))completion appUserID:(NSString *)appUserID {
//    NSArray <RCSubscriberAttribute *> *unsyncedAttributesForAppUserID: = [self.deviceCache unsyncedAttributesForAppUserID:appUserID];

    RCSubscriberAttribute *attribute =
        [[RCSubscriberAttribute alloc] initWithKey:@"$email" value:@"someemail@revenuecat.com" appUserID:appUserID];
    [self.backend postSubscriberAttributes:unsyncedAttributes appUserID:appUserID completion:^(NSError *error) {
        if (error == nil) {
            [self markAttributesAsSynced];
        }
        completion(error);
    }];
}

- (void)markAttributesAsSynced {
    // TODO
}

- (void)storeAttributeLocallyIfNeededWithKey:(NSString *)key value:(NSString *)value {
    if ([self currentValueForAttributeWithKey:key] != value) {
        [self storeAttributeLocallyWithKey:key value:value];
    }
}

- (void)storeAttributeLocallyWithKey:(NSString *)key value:(NSString *)value {
    if ([self currentValueForAttributeWithKey:key] != value) {
        RCSubscriberAttribute *subscriberAttribute = [[RCSubscriberAttribute alloc] init];
        [self.deviceCache storeSubscriberAttribute:subscriberAttribute];
    }
}

- (NSString *)currentValueForAttributeWithKey:(NSString *)key {
    RCSubscriberAttribute *attribute = [self.deviceCache subscriberAttributeWithKey:key appUserID:nil];
    return attribute.value;
}

- (NSUInteger)numberOfUnsyncedAttributes {
    return [self.deviceCache numberOfUnsyncedAttributesForAppUserID:nil];
}

@end


NS_ASSUME_NONNULL_END
