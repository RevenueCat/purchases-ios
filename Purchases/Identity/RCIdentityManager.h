//
// Created by RevenueCat.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCPurchaserInfo, RCPurchaserInfoManager, RCBackend, RCDeviceCache;

NS_ASSUME_NONNULL_BEGIN

@interface RCIdentityManager : NSObject

@property (nonatomic, readonly) NSString *currentAppUserID;
@property (nonatomic, readonly) BOOL currentUserIsAnonymous;

- (instancetype)initWith:(RCDeviceCache *)deviceCache
                 backend:(RCBackend *)backend
    purchaserInfoManager:(RCPurchaserInfoManager *)purchaserInfoManager;

- (void)configureWithAppUserID:(nullable NSString *)appUserID;

- (void)logInWithAppUserID:(NSString *)newAppUserID
                completion:(void (^)(RCPurchaserInfo * _Nullable purchaserInfo,
                                     BOOL created,
                                     NSError * _Nullable error))completion;

- (void)logOutWithCompletion:(void (^)(NSError * _Nullable error))completion;

#pragma MARK - deprecated methods

- (void)identifyAppUserID:(NSString *)appUserID completion:(void (^)(NSError * _Nullable error))completion;

- (void)createAliasForAppUserID:(NSString *)alias completion:(void (^)(NSError * _Nullable error))completion;

- (void)resetAppUserID;

@end

NS_ASSUME_NONNULL_END