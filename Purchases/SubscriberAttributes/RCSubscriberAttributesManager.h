//
// Created by RevenueCat on 2/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSubscriberAttribute.h"

NS_ASSUME_NONNULL_BEGIN

@class RCBackend;
@class RCDeviceCache;
@class RCSubscriberAttribute;
@class RCAttributionFetcher;


@interface RCSubscriberAttributesManager : NSObject

- (instancetype)initWithBackend:(nullable RCBackend *)backend
                    deviceCache:(nullable RCDeviceCache *)deviceCache
             attributionFetcher:(nullable RCAttributionFetcher *)attributionFetcher;

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes appUserID:(NSString *)appUserID;

- (void)setEmail:(nullable NSString *)email appUserID:(NSString *)appUserID;

- (void)setPhoneNumber:(nullable NSString *)phoneNumber appUserID:(NSString *)appUserID;

- (void)setDisplayName:(nullable NSString *)displayName appUserID:(NSString *)appUserID;

- (void)setPushToken:(nullable NSData *)pushToken appUserID:(NSString *)appUserID;

- (void)setPushTokenString:(nullable NSString *)pushToken appUserID:(NSString *)appUserID;

- (void)setAdjustID:(nullable NSString *)adjustID appUserID:(NSString *)appUserID;

- (void)setAppsflyerID:(nullable NSString *)appsflyerID appUserID:(NSString *)appUserID;

- (void)setFBAnonymousID:(nullable NSString *)fbAnonymousID appUserID:(NSString *)appUserID;

- (void)setMparticleID:(nullable NSString *)mparticleID appUserID:(NSString *)appUserID;

- (void)setOnesignalID:(nullable NSString *)onesignalID appUserID:(NSString *)appUserID;

- (void)setMediaSource:(nullable NSString *)mediaSource appUserID:(NSString *)appUserID;

- (void)setCampaign:(nullable NSString *)campaign appUserID:(NSString *)appUserID;

- (void)setAdGroup:(nullable NSString *)adGroup appUserID:(NSString *)appUserID;

- (void)setAd:(nullable NSString *)ad appUserID:(NSString *)appUserID;

- (void)setKeyword:(nullable NSString *)keyword appUserID:(NSString *)appUserID;

- (void)setCreative:(nullable NSString *)creative appUserID:(NSString *)appUserID;

- (void)syncAttributesForAllUsersWithCurrentAppUserID:(NSString *)currentAppUserID;

- (RCSubscriberAttributeDict)unsyncedAttributesByKeyForAppUserID:(NSString *)appUserID;

- (void)markAttributesAsSynced:(RCSubscriberAttributeDict)syncedAttributes
                     appUserID:(NSString *)appUserID;

- (void)collectDeviceIdentifiersForAppUserID:(NSString *)appUserID;

@end


NS_ASSUME_NONNULL_END
