//
// Created by RevenueCat.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import "RCUserManager.h"
#import "RCUtils.h"
#import "RCBackend.h"
#import "RCPurchasesErrorUtils.h"

@interface RCUserManager ()

@property (nonatomic) RCDeviceCache *deviceCache;

@property (nonatomic) RCBackend *backend;

@end

@implementation RCUserManager

- (instancetype)initWith:(RCDeviceCache *)deviceCache backend:(RCBackend *)backend
{
    self = [super init];
    if (self) {
        self.deviceCache = deviceCache;
        self.backend = backend;
    }

    return self;
}

- (NSString *)generateRandomID
{
    return [NSString stringWithFormat:@"$RCAnonymousID:%@", [[NSUUID.new.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString]];
}

- (void)configureWithAppUserID:(nullable NSString *)appUserID
{
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
}

- (void)identifyAppUserID:(NSString *)appUserID withCompletionBlock:(void (^)(NSError *_Nullable error))completion
{
    if (self.currentUserIsAnonymous) {
        RCDebugLog(@"Identifying from an anonymous ID: %@. An alias will be created.", self.currentAppUserID);
        [self createAlias:appUserID withCompletionBlock:completion];
    } else {
        RCDebugLog(@"Changing App User ID: %@ -> %@", self.currentAppUserID, appUserID);
        [self.deviceCache clearCachesForAppUserID:self.currentAppUserID];
        [self saveAppUserID:appUserID];
        completion(nil);
    }
}

- (void)saveAppUserID:(NSString *)appUserID
{
    [self.deviceCache cacheAppUserID:appUserID];
}

- (void)createAlias:(NSString *)alias withCompletionBlock:(void (^)(NSError *_Nullable error))completion
{
    RCDebugLog(@"Creating an alias to %@ from %@", self.currentAppUserID, alias);
    [self.backend createAliasForAppUserID:self.currentAppUserID withNewAppUserID:alias completion:^(NSError *_Nullable error) {
        if (error == nil) {
            RCDebugLog(@"Alias created");
            [self.deviceCache clearCachesForAppUserID:self.currentAppUserID];
            [self saveAppUserID:alias];
        }
        completion(error);
    }];
}

- (void)resetAppUserID
{
    [self.deviceCache clearCachesForAppUserID:self.currentAppUserID];
    NSString *randomId = [self generateRandomID];
    [self saveAppUserID:randomId];
}

- (NSString *)currentAppUserID
{
    return [self.deviceCache cachedAppUserID];
}

- (BOOL)currentUserIsAnonymous
{
    BOOL currentAppUserIDLooksAnonymous = [[self.deviceCache cachedAppUserID] rangeOfString:@"\\$RCAnonymousID:([a-z0-9]{32})$" options:NSRegularExpressionSearch].length > 0;
    BOOL b = [self.deviceCache.cachedAppUserID isEqualToString:self.deviceCache.cachedLegacyAppUserID];
    return currentAppUserIDLooksAnonymous || b;
}

@end