//
// Created by RevenueCat.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import "RCIdentityManager.h"
#import "RCLogUtils.h"
#import "RCBackend.h"
#import "RCPurchasesErrorUtils.h"


@interface RCIdentityManager ()

@property (nonatomic) RCDeviceCache *deviceCache;

@property (nonatomic) RCBackend *backend;

@end

@implementation RCIdentityManager

- (instancetype)initWith:(RCDeviceCache *)deviceCache backend:(RCBackend *)backend {
    self = [super init];
    if (self) {
        self.deviceCache = deviceCache;
        self.backend = backend;
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
                RCDebugLog(@"Generated New App User ID - %@", appUserID);
            }
        }
    }

    [self saveAppUserID:appUserID];
    [self.deviceCache cleanupSubscriberAttributes];
}

- (void)identifyAppUserID:(NSString *)appUserID withCompletionBlock:(void (^)(NSError *_Nullable error))completion {
    if (self.currentUserIsAnonymous) {
        RCDebugLog(@"Identifying from an anonymous ID: %@. An alias will be created.", self.currentAppUserID);
        [self createAlias:appUserID withCompletionBlock:completion];
    } else {
        RCDebugLog(@"Changing App User ID: %@ -> %@", self.currentAppUserID, appUserID);
        [self.deviceCache clearCachesForAppUserID:self.currentAppUserID andSaveNewUserID:appUserID];
        completion(nil);
    }
}

- (void)saveAppUserID:(NSString *)appUserID {
    [self.deviceCache cacheAppUserID:appUserID];
}

- (void)createAlias:(NSString *)alias withCompletionBlock:(void (^)(NSError *_Nullable error))completion {
    NSString *currentAppUserID = self.currentAppUserID;
    if (!currentAppUserID) {
        RCDebugLog(@"Couldn't create an alias because the currentAppUserID is null. "
                   "This might happen if the entry in UserDefaults is missing.");
        completion(RCPurchasesErrorUtils.missingAppUserIDError);
        return;
    }
    RCDebugLog(@"Creating an alias from %@ to %@", currentAppUserID, alias);
    [self.backend createAliasForAppUserID:currentAppUserID withNewAppUserID:alias completion:^(NSError *_Nullable error) {
        if (error == nil) {
            RCDebugLog(@"Alias created");
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

@end
