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
    [auth identifyCurrentUserAsID:@"" completion:^(RCCustomerInfo *i, BOOL created, NSError *error) { }];
    [auth logOutWithCompletion:^(RCCustomerInfo *i, NSError *error) { }];

    RCIdentity *siwa = [RCIdentity identityWithSignInWithAppleToken:[NSData data]];
    RCIdentitySource *source = siwa.identitySource;

    RCIdentitySource *anonymousSource = [RCIdentitySource anonymous];
    RCIdentitySource *appleSource = [RCIdentitySource signInWithApple];
    RCIdentitySource *googleSource = [RCIdentitySource google];
    RCIdentitySource *firebase = [RCIdentitySource firebase];
    RCIdentitySource *facebook = [RCIdentitySource facebook];
    RCIdentitySource *oidc = [RCIdentitySource oidc];
}

- (void)authenticatorDidEncounterError:(NSError *)error { }

@end
