//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSubscriberAttributesManager.h"
#import "RCSpecialSubscriberAttributes.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttributesManager ()


@end


NS_ASSUME_NONNULL_END


@implementation RCSubscriberAttributesManager

#pragma MARK - Public methods

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        [self setAttributeWithKey:key value:value];
    }];
}

- (void)setEmail:(NSString *)email {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_EMAIL value:email];
}

- (void)setPhoneNumber:(NSString *)phoneNumber {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PHONE_NUMBER value:phoneNumber];
}

- (void)setDisplayName:(NSString *)displayName {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_DISPLAY_NAME value:displayName];
}

- (void)setPushToken:(NSString *)pushToken {
    [self setAttributeWithKey:SPECIAL_ATTRIBUTE_PUSH_TOKEN value:pushToken];
}

#pragma MARK - Private methods

- (void)setAttributeWithKey:(NSString *)key value:(NSString *)value {
    [self storeAttributeLocallyWithKey:key value:value];
    [self syncIfNeeded];
}

- (void)syncIfNeeded {

}

- (void)storeAttributeLocallyWithKey:(NSString *)key value:(NSString *)value {

}

@end
