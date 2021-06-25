//
//  RCEntitlementInfoAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 6/25/21.
//  Copyright © 2021 Purchases. All rights reserved.
//


@import Purchases;
@import PurchasesCoreSwift;

#import "RCEntitlementInfoAPI.h"

@implementation RCEntitlementInfoAPI

+ (void)checkAPI {
    RCEntitlementInfo *ri = [[RCEntitlementInfo alloc] initWithEntitlementId:@""
                                                             entitlementData:@{}
                                                                 productData:@{}
                                                               dateFormatter:[[NSDateFormatter alloc] init]
                                                                 requestDate:NSDate.now];
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

    NSLog(ri, wr, pt, lpd, opd, ed, s, pi, is, uda, bida, ot);
}

@end
