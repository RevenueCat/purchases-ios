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


@interface RCSubscriberAttributesManager : NSObject

- (instancetype)initWithBackend:(nullable RCBackend *)backend
                    deviceCache:(nullable RCDeviceCache *)deviceCache;

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes appUserID:(NSString *)appUserID;

- (void)setEmail:(nullable NSString *)email appUserID:(NSString *)appUserID;

- (void)setPhoneNumber:(nullable NSString *)phoneNumber appUserID:(NSString *)appUserID;

- (void)setDisplayName:(nullable NSString *)displayName appUserID:(NSString *)appUserID;

- (void)setPushToken:(nullable NSData *)pushToken appUserID:(NSString *)appUserID;

- (void)setPushTokenString:(nullable NSString *)pushToken appUserID:(NSString *)appUserID;

- (void)syncIfNeededWithAppUserID:(NSString *)appUserID completion:(void (^)(NSError *_Nullable error))completion;

- (RCSubscriberAttributeDict)unsyncedAttributesByKeyForAppUserID:(NSString *)appUserID;

- (void)markAttributesAsSynced:(RCSubscriberAttributeDict)syncedAttributes
                     appUserID:(NSString *)appUserID;

@end


NS_ASSUME_NONNULL_END
