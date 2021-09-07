//
//  RCEntitlementInfoAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 6/25/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import RevenueCat;

#import "RCEntitlementInfoAPI.h"

@implementation RCEntitlementInfoAPI

+ (void)checkAPI {
    RCEntitlementInfo *ri;
    NSString *i = ri.identifier;
    BOOL ia = [ri isActive];
    BOOL wr = [ri willRenew];
    RCPeriodType pt = [ri periodType];
    NSDate *lpd = [ri latestPurchaseDate];
    NSDate *opd = [ri originalPurchaseDate];
    NSDate *ed = [ri expirationDate];
    RCStore s = [ri store];
    NSString *pi = [ri productIdentifier];
    BOOL is = [ri isSandbox];
    NSDate *uda = [ri unsubscribeDetectedAt];
    NSDate *bida = [ri billingIssueDetectedAt];
    RCPurchaseOwnershipType ot = [ri ownershipType];

    NSLog(i, ia, ri, wr, pt, lpd, opd, ed, s, pi, is, uda, bida, ot);
}

+ (void)checkEnums {
    RCStore rs = RCAppStore;
    rs = RCMacAppStore;
    rs = RCPlayStore;
    rs = RCStripe;
    rs = RCPromotional;
    rs = RCUnknownStore;

    RCPeriodType pr = RCIntro;
    pr = RCTrial;
    pr = RCNormal;
}

@end
