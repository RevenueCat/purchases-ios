//
//  RCDeepLinkAPI.m
//  APITester
//
//  Created by Toni Rico on 10/30/24.
//  Copyright © 2024 Purchases. All rights reserved.
//

@import RevenueCat;
#import "RCDeepLinkAPI.h"

@implementation RCDeepLinkAPI

+ (void)checkAPI {
    RCDeepLink *deepLink;
    WebPurchaseRedemption *redemptionLink = (WebPurchaseRedemption *)deepLink;

    NSLog(deepLink, redemptionLink);
}

@end
