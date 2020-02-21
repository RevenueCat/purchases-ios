//
// Created by Andrés Boedo on 2/21/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPurchases.h"

@class RCSubscriberAttribute, RCSubscriberAttributesManager;

@interface RCPurchases (SubscriberAttributes)

#pragma mark Subscriber Attributes

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes;

- (void)setEmail:(nullable NSString *)email;

- (void)setPhoneNumber:(nullable NSString *)phoneNumber;

- (void)setDisplayName:(nullable NSString *)displayName;

- (void)setPushToken:(nullable NSString *)pushToken;

@property (nonatomic) RCSubscriberAttributesManager *subscriberAttributesManager;

- (void)configureSubscriberAttributesManager;
- (void)clearSubscriberAttributesCache;
- (NSArray <RCSubscriberAttribute *> *)unsyncedAttributes;

@end
