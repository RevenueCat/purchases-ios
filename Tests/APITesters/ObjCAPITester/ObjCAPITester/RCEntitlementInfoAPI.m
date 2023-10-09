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
    BOOL iaae = [ri isActiveInAnyEnvironment];
    BOOL iace = [ri isActiveInCurrentEnvironment];
    BOOL wr = [ri willRenew];
    RCPeriodType pt = [ri periodType];
    NSDate *lpd = [ri latestPurchaseDate];
    NSDate *opd = [ri originalPurchaseDate];
    NSDate *ed = [ri expirationDate];
    RCStore s = [ri store];
    NSString *pi = [ri productIdentifier];
    NSString *ppi = [ri productPlanIdentifier];
    BOOL is = [ri isSandbox];
    NSDate *uda = [ri unsubscribeDetectedAt];
    NSDate *bida = [ri billingIssueDetectedAt];
    RCPurchaseOwnershipType ot = [ri ownershipType];
    NSDictionary<NSString *, id> *rawData = [ri rawData];

    if (@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)) {
        RCVerificationResult ver __unused = [ri verification];
    }

    NSLog(i, ia, iaae, iace, ri, wr, pt, lpd, opd, ed, s, pi, ppi, is, uda, bida, ot, rawData);
}

+ (void)checkEnums {
    RCStore rs = RCAppStore;
    switch(rs) {
        case RCAppStore:
        case RCMacAppStore:
        case RCPlayStore:
        case RCStripe:
        case RCPromotional:
        case RCAmazon:
        case RCUnknownStore:
            NSLog(@"%ld", (long)rs);
            break;
    }


    RCPeriodType pr = RCIntro;
    switch(pr) {
        case RCIntro:
        case RCTrial:
        case RCNormal:
            NSLog(@"%ld", (long)pr);
    }
}

@end
