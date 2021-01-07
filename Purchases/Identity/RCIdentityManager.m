//
// Created by RevenueCat.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import "RCIdentityManager.h"
#import "RCLogUtils.h"
#import "RCBackend.h"
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

- (void)identifyAppUserID:(NSString *)appUserID completionBlock:(void (^)(NSError *_Nullable error))completion {
    if (self.currentUserIsAnonymous) {
        RCUserLog(RCStrings.identity.identifying_anon_id, self.currentAppUserID);
        [self createAliasForAppUserID:appUserID completionBlock:completion];
    } else {
        RCUserLog(RCStrings.identity.changing_app_user_id, self.currentAppUserID, appUserID);
        [self.deviceCache clearCachesForAppUserID:self.currentAppUserID andSaveNewUserID:appUserID];
        completion(nil);
    }
}

- (void)saveAppUserID:(NSString *)appUserID {
    [self.deviceCache cacheAppUserID:appUserID];
}

- (void)createAliasForAppUserID:(NSString *)alias completionBlock:(void (^)(NSError *_Nullable error))completion {
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
    [self.deviceCache clearCachesForAppUserID:self.currentAppUserID andSaveNewUserID:randomId];
}

- (NSString *)currentAppUserID {
    return [self.deviceCache cachedAppUserID];
}

- (BOOL)currentUserIsAnonymous {
    BOOL currentAppUserIDLooksAnonymous = [[self.deviceCache cachedAppUserID] rangeOfString:@"\\$RCAnonymousID:([a-z0-9]{32})$" options:NSRegularExpressionSearch].length > 0;
    BOOL isLegacyAnonymousAppUserID = [self.deviceCache.cachedAppUserID isEqualToString:self.deviceCache.cachedLegacyAppUserID];
    return currentAppUserIDLooksAnonymous || isLegacyAnonymousAppUserID;
}

- (void)logInAppUserID:(NSString *)newAppUserID
       completionBlock:(void (^)(RCPurchaserInfo * _Nullable purchaserInfo, BOOL created, NSError *error))completion {
    if (!newAppUserID || [newAppUserID isEqualToString:@""]) {
        RCErrorLog(@"%@", RCStrings.identity.creating_alias_failed_null_currentappuserid);
        completion(nil, NO, RCPurchasesErrorUtils.missingAppUserIDError);
        return;
    }

    NSString *currentAppUserID = self.currentAppUserID;
    if (!currentAppUserID) {
        RCWarnLog(@"%@", RCStrings.identity.logging_in_with_initial_appuserid_nil);
    }

    if ([newAppUserID isEqualToString:currentAppUserID]) {
        RCWarnLog(@"%@", RCStrings.identity.logging_in_with_nil_appuserid);
        [self.purchaserInfoManager purchaserInfoWithAppUserID:currentAppUserID
                                              completionBlock:^(RCPurchaserInfo *purchaserInfo, NSError *error) {
                                                  completion(purchaserInfo, NO, error);
                                              }];
        return;
    }

    [self.backend logInWithCurrentAppUserID:currentAppUserID
                               newAppUserID:newAppUserID
                                 completion:^(RCPurchaserInfo *purchaserInfo, BOOL created, NSError *error) {
        if (error == nil) {
            RCUserLog(@"%@", RCStrings.identity.login_success);
            [self.deviceCache clearCachesForAppUserID:currentAppUserID andSaveNewUserID:newAppUserID];
        }
        completion(purchaserInfo, created, error);
    }];
}
@end
