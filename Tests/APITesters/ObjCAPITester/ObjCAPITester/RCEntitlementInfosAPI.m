//
//  RCEntitlementInfosAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 6/28/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import RevenueCat;

#import "RCEntitlementInfosAPI.h"

@implementation RCEntitlementInfosAPI

+ (void)checkAPI {
    RCEntitlementInfos *ei;
    NSDictionary<NSString *, RCEntitlementInfo *> *all = ei.all;
    NSDictionary<NSString *, RCEntitlementInfo *> *active = ei.active;
    NSDictionary<NSString *, RCEntitlementInfo *> *activeInAnyEnvironment = ei.activeInAnyEnvironment;
    NSDictionary<NSString *, RCEntitlementInfo *> *activeInCurrentEnvironment = ei.activeInCurrentEnvironment;
    RCEntitlementInfo *e = [ei objectForKeyedSubscript:@""];

    if (@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)) {
        RCVerificationResult verification __unused = ei.verification;
    }

    NSLog(ei, all, active, activeInAnyEnvironment, activeInCurrentEnvironment, e);
}

@end
