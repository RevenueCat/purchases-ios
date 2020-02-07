//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttributesManager : NSObject

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes;

- (void)setEmail:(NSString *)email;

- (void)setPhoneNumber:(NSString *)phoneNumber;

- (void)setDisplayName:(NSString *)displayName;

- (void)setPushToken:(NSString *)pushToken;

@end


NS_ASSUME_NONNULL_END
