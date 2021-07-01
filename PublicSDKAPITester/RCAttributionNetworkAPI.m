//
//  RCAttributionNetworkAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 7/1/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import PurchasesCoreSwift;

#import "RCAttributionNetworkAPI.h"

@implementation RCAttributionNetworkAPI

+ (void)checkEnums {
    NSLog(@"%zd%zd%zd%zd%zd%zd%zd",
          RCAttributionNetworkAppleSearchAds,
          RCAttributionNetworkAdjust,
          RCAttributionNetworkAppsFlyer,
          RCAttributionNetworkBranch,
          RCAttributionNetworkTenjin,
          RCAttributionNetworkFacebook,
          RCAttributionNetworkMParticle);
}

@end
