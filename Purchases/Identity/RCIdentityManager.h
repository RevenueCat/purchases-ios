//
// Created by RevenueCat.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCDeviceCache.h"

@class RCPurchaserInfo, RCBackend;

NS_ASSUME_NONNULL_BEGIN

@interface RCIdentityManager : NSObject

@property (nonatomic, readonly) NSString *currentAppUserID;

@property (nonatomic, readonly) RCDeviceCache *deviceCache;

@property (nonatomic, readonly) RCBackend *backend;

@property (nonatomic, readonly) BOOL currentUserIsAnonymous;

- (instancetype)initWith:(RCDeviceCache *)deviceCache backend:(RCBackend *)backend;

- (NSString *)generateRandomID;

- (void)configureWithAppUserID:(nullable NSString *)appUserID;

- (void)identifyAppUserID:(NSString *)appUserID completionBlock:(void (^)(NSError * _Nullable error))completion;

- (void)createAliasForAppUserID:(NSString *)alias completionBlock:(void (^)(NSError * _Nullable error))completion;

- (void)resetAppUserID;

- (void)logInAppUserID:(NSString *)newAppUserID completionBlock:(void (^)(NSError *))completion;

@end

NS_ASSUME_NONNULL_END