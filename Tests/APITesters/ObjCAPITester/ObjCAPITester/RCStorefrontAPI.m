//
//  RCStorefrontAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 4/13/22.
//

#import "RCStorefrontAPI.h"

@import RevenueCat;

@implementation RCStorefrontAPI

+ (void)checkAPI {
    RCStorefront *storefront;

    NSString *identifier = storefront.identifier;
    NSString *countryCode = storefront.countryCode;

    SKStorefront *sk1storefront = storefront.sk1Storefront;

    RCStorefront *currentStorefront = [RCStorefront sk1CurrentStorefront];

    NSLog(identifier, countryCode, sk1storefront, currentStorefront);
}

@end
