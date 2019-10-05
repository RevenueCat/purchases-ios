//
//  RCDeviceCache.h
//  Purchases
//
// Created by RevenueCat.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import "RCUserIdentity.h"
#import "RCUtils.h"
#import "RCBackend.h"
#import "RCPurchasesErrorUtils.h"

@interface RCUserIdentity ()

@property (nonatomic) RCDeviceCache *deviceCache;

@property (nonatomic) RCBackend *backend;

@property (nonatomic) NSString *appUserID;

@property (nonatomic) BOOL isAnonymous;

@end

@implementation RCUserIdentity

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

- (BOOL)configureAppUserID:(nullable NSString *)appUserID
{
    if ([self isAppUserIDAnonymous:appUserID]) {
        RCErrorLog(@"ERROR: Cannot configure Purchases with a RevenueCat anonymous Id. See https://docs.revenuecat.com/docs/user-ids");
        return NO;
    }
    BOOL isAnonymous = false;
    if (appUserID == nil) {
        appUserID = [self.deviceCache cachedAppUserID];
        if (appUserID == nil) {
            appUserID = [self generateRandomID];
            isAnonymous = true;
            RCDebugLog(@"Generated New App User ID - %@", appUserID);
        } else {
            isAnonymous = [self.deviceCache isAnonymous];
        }
    }
    [self saveAppUserID:appUserID isAnonymous:isAnonymous];
    return YES;
}

- (void)identifyAppUserID:(NSString *)appUserID withCompletionBlock:(void (^)(NSError *_Nullable error))completion
{
    if ([self isAppUserIDAnonymous:appUserID]) {
        completion([RCPurchasesErrorUtils invalidAppUserIDErrorWithMethodName:@"identify"]);
        return;
    }
    if (self.isAnonymous) {
        RCDebugLog(@"Identifying from an anonymous ID: %@. An alias will be created.", self.appUserID);
        [self createAlias:appUserID withCompletionBlock:completion];
    } else {
        RCDebugLog(@"Changing App User ID: %@ -> %@", self.appUserID, appUserID);
        [self.deviceCache clearCachesForAppUserID:self.appUserID];
        [self saveAppUserID:appUserID isAnonymous:NO];
    }
}

- (void)saveAppUserID:(NSString *)appUserID isAnonymous:(BOOL)isAnonymous
{
    self.appUserID = appUserID;
    self.isAnonymous = isAnonymous;
    [self.deviceCache cacheAppUserID:appUserID isAnonymous:isAnonymous];
}

- (void)createAlias:(NSString *)alias withCompletionBlock:(void (^)(NSError *_Nullable error))completion
{
    if ([self isAppUserIDAnonymous:alias]) {
        completion([RCPurchasesErrorUtils invalidAppUserIDErrorWithMethodName:@"createAlias"]);
        return;
    }
    RCDebugLog(@"Creating an alias to %@ from %@", self.appUserID, alias);
    [self.backend createAliasForAppUserID:self.appUserID withNewAppUserID:alias completion:^(NSError *_Nullable error) {
        if (error == nil) {
            RCDebugLog(@"Alias created");
            [self.deviceCache clearCachesForAppUserID:self.appUserID];
            [self saveAppUserID:alias isAnonymous:NO];
        }
        completion(error);
    }];
}

- (void)resetAppUserID
{
    [self.deviceCache clearCachesForAppUserID:self.appUserID];
    NSString *randomId = [self generateRandomID];
    [self saveAppUserID:randomId isAnonymous:true];
}

- (BOOL)isAppUserIDAnonymous:(NSString *)appUserID
{
    if([appUserID length]==0){
        return NO;
    }
    NSError *error = NULL;
    NSString *regExPattern = @"\\$RCAnonymousID:([a-z0-9]{32})$";
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:regExPattern options:0 error:&error];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:appUserID options:0 range:NSMakeRange(0, [appUserID length])];
    return regExMatches > 0;
}

@end