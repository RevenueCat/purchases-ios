//
//  RCAttributionNetworkAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 7/1/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import RevenueCat;

#import "RCAttributionNetworkAPI.h"

@implementation RCAttributionNetworkAPI

+ (void)checkEnums {
    RCAttributionNetwork network = RCAttributionNetworkAdjust;
    switch(network) {
        case RCAttributionNetworkAdServices:
        case RCAttributionNetworkAppleSearchAds:
        case RCAttributionNetworkAdjust:
        case RCAttributionNetworkAppsFlyer:
        case RCAttributionNetworkBranch:
        case RCAttributionNetworkTenjin:
        case RCAttributionNetworkFacebook:
        case RCAttributionNetworkMParticle:
            NSLog(@"%ld", (long)network);
    }
}

@end
