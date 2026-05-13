//
//  RCBillingPlanTypeAPI.m
//  ObjcAPITester
//
//  Created by Will Taylor on 5/13/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

#import "RCBillingPlanTypeAPI.h"

@import RevenueCat;

@implementation RCBillingPlanTypeAPI

+ (void)checkAPI {
    RCBillingPlanType *monthly __unused = [RCBillingPlanType RCMonthly];
    RCBillingPlanType *upFront __unused = [RCBillingPlanType RCUpFront];
}


@end
