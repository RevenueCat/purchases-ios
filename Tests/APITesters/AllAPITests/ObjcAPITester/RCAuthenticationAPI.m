//
//  RCAuthenticationAPI.m
//  ObjcAPITester
//
//  Created by Dave DeLong on 8/13/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

#import "RCAuthenticationAPI.h"

@import RevenueCat;

@interface RCAuthenticationAPI () <RCPurchasesAuthenticationDelegate>
@end

@implementation RCAuthenticationAPI

+ (void)checkAPI {
    RCPurchases *p = [RCPurchases configureWithAPIKey:@""];

    RCPurchasesAuthentication *auth = p.authentication;
    auth.delegate = nil;

    [auth identifyCurrentUserAsID:@"" completion:^(RCCustomerInfo *i, BOOL created, NSError *error) { }];
    [auth logOutWithCompletion:^(RCCustomerInfo *i, NSError *error) { }];

    RCIdentity *siwa = [RCIdentity identityWithSignInWithAppleToken:[NSData data]];
    RCIdentitySource *__unused source = siwa.identitySource;

    RCIdentitySource *__unused anonymousSource = [RCIdentitySource anonymous];
    RCIdentitySource *__unused appleSource = [RCIdentitySource signInWithApple];
    RCIdentitySource *__unused googleSource = [RCIdentitySource google];
    RCIdentitySource *__unused firebase = [RCIdentitySource firebase];
    RCIdentitySource *__unused facebook = [RCIdentitySource facebook];
    RCIdentitySource *__unused oidc = [RCIdentitySource oidc];
}

- (void)authenticatorDidEncounterError:(NSError *)error { }

- (void)authenticatorDidUpdateAccessToken:(NSString *)newAccessToken { }

@end
