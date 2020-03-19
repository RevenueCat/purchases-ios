//
// Created by Andrés Boedo on 2/21/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPurchases.h"
#import "RCSubscriberAttribute.h"

@class RCSubscriberAttribute, RCSubscriberAttributesManager;

NS_ASSUME_NONNULL_BEGIN


@interface RCPurchases (SubscriberAttributes)

- (void)_setAttributes:(NSDictionary<NSString *, NSString *> *)attributes;
- (void)_setEmail:(nullable NSString *)email;
- (void)_setPhoneNumber:(nullable NSString *)phoneNumber;
- (void)_setDisplayName:(nullable NSString *)displayName;
- (void)_setPushToken:(nullable NSData *)pushToken;
- (void)_setPushTokenString:(nullable NSString *)pushToken;

- (void)configureSubscriberAttributesManager;
- (RCSubscriberAttributeDict)unsyncedAttributesByKey;
- (void)markAttributesAsSyncedIfNeeded:(RCSubscriberAttributeDict)syncedAttributes
                             appUserID:(NSString *)appUserID
                                 error:(nullable NSError *)error;
@end

@interface RCPurchases ()

@property (nonatomic) RCSubscriberAttributesManager *subscriberAttributesManager;

@end


NS_ASSUME_NONNULL_END
