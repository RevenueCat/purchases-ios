//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSubscriberAttributesManager.h"
#import "RCSpecialSubscriberAttributes.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttributesManager ()

#define DEFAULT_TOTAL_ATTRIBUTES_TO_THROTTLE 10

@property (nonatomic, assign) NSUInteger totalAttributesToThrottle;

@end




@implementation RCSubscriberAttributesManager

#pragma MARK - Public methods

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        [self setAttributeWithKey:key value:value];
    }];
}

- (void)setEmail:(nullable NSString *)email {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_EMAIL value:email];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PHONE_NUMBER value:phoneNumber];
}

- (void)setDisplayName:(nullable NSString *)displayName {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_DISPLAY_NAME value:displayName];
}

- (void)setPushToken:(nullable NSString *)pushToken {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PUSH_TOKEN value:pushToken];
}

- (void)clearAttributes {

}

#pragma MARK - Private methods

- (void)setAttributeWithKey:(nullable NSString *)key value:(NSString *)value {
    [self storeAttributeLocallyIfNeededWithKey:key value:value];
    [self syncIfNeeded];
}

- (void)syncIfNeeded {
    if (self.numberOfUnsyncedAttributes > self.totalAttributesToThrottle) {
        [self syncAttributes];
    }
}

- (void)syncAttributes {

}

- (void)storeAttributeLocallyIfNeededWithKey:(NSString *)key value:(NSString *)value {
    if ([self currentValueForAttributeWithKey:key] != value) {
        [self storeAttributeLocallyWithKey:key value: value];
    }
}

- (void)storeAttributeLocallyWithKey:(NSString *)key value:(NSString *)value {

}

- (NSString *)currentValueForAttributeWithKey:(NSString *)key {
    return nil;
}

- (NSUInteger)numberOfUnsyncedAttributes{
    return 0;
}

@end

NS_ASSUME_NONNULL_END
