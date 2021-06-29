//
//  RCEntitlementInfosAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 6/28/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import Purchases;
@import PurchasesCoreSwift;
#import "RCEntitlementInfosAPI.h"

@implementation RCEntitlementInfosAPI

+ (void)checkAPI {
    RCEntitlementInfos *ei = [[RCEntitlementInfos alloc] initWithEntitlementsData:nil
                                                                    purchasesData:@{}
                                                                    dateFormatter:[[NSDateFormatter alloc] init]
                                                                      requestDate:nil];
    NSDictionary<NSString *, RCEntitlementInfo *> *all = ei.all;
    NSDictionary<NSString *, RCEntitlementInfo *> *active = ei.active;
    RCEntitlementInfo *e = [ei objectForKeyedSubscript:@""];

    NSLog(ei, all, active, e);
}

@end
