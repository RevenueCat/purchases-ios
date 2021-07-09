//
// Created by RevenueCat.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import "RCIdentityManager.h"
#import "RCLogUtils.h"
#import "RCBackend.h"
#import "RCDeviceCache.h"
#import "RCPurchasesErrorUtils.h"
#import "RCPurchaserInfoManager.h"
@import PurchasesCoreSwift;


@interface RCIdentityManager ()

@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCPurchaserInfoManager *purchaserInfoManager;

@end

@implementation RCIdentityManager

- (instancetype)initWith:(RCDeviceCache *)deviceCache
                 backend:(RCBackend *)backend
    purchaserInfoManager:(RCPurchaserInfoManager *)purchaserInfoManager {
    self = [super init];
    if (self) {
        self.deviceCache = deviceCache;
        self.backend = backend;
        self.purchaserInfoManager = purchaserInfoManager;
    }

    return self;
}

- (NSString *)generateRandomID {
    NSString *uuid = [NSUUID.new.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return [NSString stringWithFormat:@"$RCAnonymousID:%@", uuid.lowercaseString];
}

- (void)configureWithAppUserID:(nullable NSString *)appUserID {
    if (appUserID == nil) {
        appUserID = [self.deviceCache cachedAppUserID];
        if (appUserID == nil) {
            appUserID = [self.deviceCache cachedLegacyAppUserID];
            if (appUserID == nil) {
                appUserID = [self generateRandomID];
                RCUserLog(RCStrings.identity.identifying_app_user_id, appUserID);
            }
        }
    }

    [self saveAppUserID:appUserID];
    [self.deviceCache cleanupSubscriberAttributes];
}

- (void)identifyAppUserID:(NSString *)appUserID completion:(void (^)(NSError *_Nullable error))completion {
    if (self.currentUserIsAnonymous) {
        RCUserLog(RCStrings.identity.identifying_anon_id, self.currentAppUserID);
        [self createAliasForAppUserID:appUserID completion:completion];
    } else {
        RCUserLog(RCStrings.identity.changing_app_user_id, self.currentAppUserID, appUserID);
        [self.deviceCache clearCachesForAppUserID:self.currentAppUserID andSaveNewUserID:appUserID];
        completion(nil);
    }
}

- (void)saveAppUserID:(NSString *)appUserID {
    [self.deviceCache cacheAppUserID:appUserID];
}

- (void)createAliasForAppUserID:(NSString *)alias completion:(void (^)(NSError *_Nullable error))completion {
    NSString *currentAppUserID = self.currentAppUserID;
    if (!currentAppUserID) {
        RCWarnLog(@"%@", RCStrings.identity.creating_alias_failed_null_currentappuserid);
        completion(RCPurchasesErrorUtils.missingAppUserIDError);
        return;
    }
    RCUserLog(RCStrings.identity.creating_alias, currentAppUserID, alias);
    [self.backend createAliasForAppUserID:currentAppUserID withNewAppUserID:alias completion:^(NSError *_Nullable error) {
        if (error == nil) {
            RCUserLog(@"%@", RCStrings.identity.creating_alias_success);
            [self.deviceCache clearCachesForAppUserID:currentAppUserID andSaveNewUserID:alias];
        }
        completion(error);
    }];
}

- (void)resetAppUserID {
    NSString *randomId = [self generateRandomID];
    NSString *oldAppUserID = self.currentAppUserID;
    [self.deviceCache clearCachesForAppUserID:oldAppUserID andSaveNewUserID:randomId];
    [self.deviceCache clearLatestNetworkAndAdvertisingIdsSentForAppUserID:oldAppUserID];
    [self.backend clearCaches];
}

- (NSString *)currentAppUserID {
    return [self.deviceCache cachedAppUserID];
}

- (BOOL)currentUserIsAnonymous {
    BOOL currentAppUserIDLooksAnonymous = [[self.deviceCache cachedAppUserID] rangeOfString:@"\\$RCAnonymousID:([a-z0-9]{32})$" options:NSRegularExpressionSearch].length > 0;
    BOOL isLegacyAnonymousAppUserID = [self.deviceCache.cachedAppUserID isEqualToString:self.deviceCache.cachedLegacyAppUserID];
    return currentAppUserIDLooksAnonymous || isLegacyAnonymousAppUserID;
}

- (void)logInWithAppUserID:(NSString *)newAppUserID
                completion:(void (^)(RCPurchaserInfo * _Nullable purchaserInfo,
                                     BOOL created,
                                     NSError * _Nullable error))completion {
    NSString *currentAppUserID = self.currentAppUserID;

    if (!currentAppUserID || !newAppUserID || [newAppUserID isEqualToString:@""]) {
        NSString *errorMessage = currentAppUserID == nil ? RCStrings.identity.logging_in_with_initial_appuserid_nil
                                                         : RCStrings.identity.logging_in_with_nil_appuserid;
        RCErrorLog(@"%@", errorMessage);
        completion(nil, NO, RCPurchasesErrorUtils.missingAppUserIDError);
        return;
    }

    if ([newAppUserID isEqualToString:currentAppUserID]) {
        RCWarnLog(@"%@", RCStrings.identity.logging_in_with_same_appuserid);
        [self.purchaserInfoManager purchaserInfoWithAppUserID:currentAppUserID
                                              completionBlock:^(RCPurchaserInfo *purchaserInfo, NSError *error) {
                                                  completion(purchaserInfo, NO, error);
                                              }];
        return;
    }

    [self.backend logInWithCurrentAppUserID:currentAppUserID
                               newAppUserID:newAppUserID
                                 completion:^(RCPurchaserInfo *purchaserInfo, BOOL created, NSError * _Nullable error) {
                                     if (error == nil) {
                                         RCUserLog(@"%@", RCStrings.identity.login_success);

                                         [self.deviceCache clearCachesForAppUserID:currentAppUserID
                                                                  andSaveNewUserID:newAppUserID];
                                         [self.purchaserInfoManager cachePurchaserInfo:purchaserInfo
                                                                          forAppUserID:newAppUserID];
                                     }
                                     completion(purchaserInfo, created, error);
    }];
}

- (void)logOutWithCompletion:(void (^)(NSError * _Nullable error))completion {
    RCLog(RCStrings.identity.logging_out_user, self.currentAppUserID);
    if (self.currentUserIsAnonymous) {
        completion(RCPurchasesErrorUtils.logOutAnonymousUserError);
        return;
    }
    [self resetAppUserID];
    RCLog(@"%@", RCStrings.identity.log_out_success);
    completion(nil);
}

@end
