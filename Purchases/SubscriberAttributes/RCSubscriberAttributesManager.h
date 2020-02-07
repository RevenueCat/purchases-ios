//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttributesManager : NSObject

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes;

- (void)setEmail:(nullable NSString *)email;

- (void)setPhoneNumber:(nullable NSString *)phoneNumber;

- (void)setDisplayName:(nullable NSString *)displayName;

- (void)setPushToken:(nullable NSString *)pushToken;

- (void)clearAttributes;

@end


NS_ASSUME_NONNULL_END
