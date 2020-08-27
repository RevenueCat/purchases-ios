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
- (void)_setAdjustID:(nullable NSString *)adjustID;
- (void)_setAppsflyerID:(nullable NSString *)appsflyerID;
- (void)_setFBAnonymousID:(nullable NSString *)fbAnonymousID;
- (void)_setMparticleID:(nullable NSString *)mparticleID;
- (void)_setOnesignalID:(nullable NSString *)onesignalID;
- (void)_setMediaSource:(nullable NSString *)mediaSource;
- (void)_setCampaign:(nullable NSString *)campaign;
- (void)_setAdGroup:(nullable NSString *)adGroup;
- (void)_setAd:(nullable NSString *)ad;
- (void)_setKeyword:(nullable NSString *)keyword;
- (void)_setCreative:(nullable NSString *)creative;
- (void)_collectDeviceIdentifiers;

- (void)configureSubscriberAttributesManager;
- (RCSubscriberAttributeDict)unsyncedAttributesByKey;
- (void)markAttributesAsSyncedIfNeeded:(nullable RCSubscriberAttributeDict)syncedAttributes
                             appUserID:(NSString *)appUserID
                                 error:(nullable NSError *)error;
@end

@interface RCPurchases ()

@property (nonatomic) RCSubscriberAttributesManager *subscriberAttributesManager;

@end


NS_ASSUME_NONNULL_END
