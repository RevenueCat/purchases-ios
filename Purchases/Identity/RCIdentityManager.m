//
// Created by RevenueCat.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import "RCIdentityManager.h"
#import "RCBackend.h"
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
                [RCLog user:[NSString stringWithFormat:RCStrings.identity.identifying_app_user_id, appUserID]];
            }
        }
    }

    [self saveAppUserID:appUserID];
    [self.deviceCache cleanupSubscriberAttributes];
}

- (void)identifyAppUserID:(NSString *)appUserID completion:(void (^)(NSError *_Nullable error))completion {
    if (self.currentUserIsAnonymous) {
        [RCLog user:[NSString stringWithFormat:RCStrings.identity.identifying_anon_id, self.currentAppUserID]];
        [self createAliasForAppUserID:appUserID completion:completion];
    } else {
        [RCLog user:[NSString stringWithFormat:RCStrings.identity.changing_app_user_id, self.currentAppUserID, appUserID]];
        [self.deviceCache clearCachesWithOldAppUserID:self.currentAppUserID andSaveWithNewUserID:appUserID];
        completion(nil);
    }
}

- (void)saveAppUserID:(NSString *)appUserID {
    [self.deviceCache cacheAppUserID:appUserID];
}

- (void)createAliasForAppUserID:(NSString *)alias completion:(void (^)(NSError *_Nullable error))completion {
    NSString *currentAppUserID = self.currentAppUserID;
    if (!currentAppUserID) {
        [RCLog warn:[NSString stringWithFormat:@"%@", RCStrings.identity.creating_alias_failed_null_currentappuserid]];
        completion(RCPurchasesErrorUtils.missingAppUserIDError);
        return;
    }
    [RCLog user:[NSString stringWithFormat:RCStrings.identity.creating_alias, currentAppUserID, alias]];
    [self.backend createAliasForAppUserID:currentAppUserID withNewAppUserID:alias completion:^(NSError *_Nullable error) {
        if (error == nil) {
            [RCLog user:[NSString stringWithFormat:@"%@", RCStrings.identity.creating_alias_success]];
            [self.deviceCache clearCachesWithOldAppUserID:currentAppUserID andSaveWithNewUserID:alias];
        }
        completion(error);
    }];
}

- (void)resetAppUserID {
    NSString *randomId = [self generateRandomID];
    NSString *oldAppUserID = self.currentAppUserID;
    [self.deviceCache clearCachesWithOldAppUserID:oldAppUserID andSaveWithNewUserID:randomId];
    [self.deviceCache clearLatestNetworkAndAdvertisingIdsSentWithAppUserID:oldAppUserID];
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
        [RCLog error:[NSString stringWithFormat:@"%@", errorMessage]];
        completion(nil, NO, RCPurchasesErrorUtils.missingAppUserIDError);
        return;
    }

    if ([newAppUserID isEqualToString:currentAppUserID]) {
        [RCLog warn:[NSString stringWithFormat:@"%@", RCStrings.identity.logging_in_with_same_appuserid]];
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
                                         [RCLog user:[NSString stringWithFormat:@"%@", RCStrings.identity.login_success]];

                                         [self.deviceCache clearCachesWithOldAppUserID:currentAppUserID
                                                                  andSaveWithNewUserID:newAppUserID];
                                         [self.purchaserInfoManager cachePurchaserInfo:purchaserInfo
                                                                          forAppUserID:newAppUserID];
                                     }
                                     completion(purchaserInfo, created, error);
    }];
}

- (void)logOutWithCompletion:(void (^)(NSError * _Nullable error))completion {
    [RCLog info:[NSString stringWithFormat:RCStrings.identity.logging_out_user, self.currentAppUserID]];
    if (self.currentUserIsAnonymous) {
        completion(RCPurchasesErrorUtils.logOutAnonymousUserError);
        return;
    }
    [self resetAppUserID];
    [RCLog info:[NSString stringWithFormat:@"%@", RCStrings.identity.log_out_success]];
    completion(nil);
}

@end
