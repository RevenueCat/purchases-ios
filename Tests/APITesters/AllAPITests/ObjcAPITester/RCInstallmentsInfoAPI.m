//
//  RCInstallmentsInfoAPI.m
//  ObjcAPITester
//
//  Created by Will Taylor on 5/11/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

#import "RCInstallmentsInfoAPI.h"

@import RevenueCat;

@implementation RCInstallmentsInfoAPI

+ (void)checkAPI {
    RCInstallmentsInfo *installmentsInfo;

    NSInteger installmentsCount __unused = installmentsInfo.installmentsCount;
    RCSubscriptionPeriod *commitmentTotalPeriod __unused = installmentsInfo.commitmentTotalPeriod;
    NSDecimal commitmentTotalPrice __unused = installmentsInfo.commitmentTotalPrice;
    NSString *commitmentTotalDisplayPrice __unused = installmentsInfo.commitmentTotalDisplayPrice;
    NSDecimal installmentBillingPrice __unused = installmentsInfo.installmentBillingPrice;
    NSString *installmentBillingDisplayPrice __unused = installmentsInfo.installmentBillingDisplayPrice;
    RCBillingPlanType *billingPlanType __unused = installmentsInfo.billingPlanType;
}

+ (void)checkInit {
    RCSubscriptionPeriod *commitmentTotalPeriod;
    RCSubscriptionPeriod *installmentPeriod;

    RCInstallmentsInfo *installmentsInfo __unused = [[RCInstallmentsInfo alloc]
                                                     initWithInstallmentsCount:12
                                                     installmentPeriod:installmentPeriod
                                                     installmentBillingPrice:[[NSDecimalNumber alloc] initWithInt:10].decimalValue
                                                     installmentBillingDisplayPrice:@"$10.00"
                                                     commitmentTotalPeriod:commitmentTotalPeriod
                                                     commitmentTotalPrice:[[NSDecimalNumber alloc] initWithInt:100].decimalValue
                                                     commitmentTotalDisplayPrice:@"$100.00"
                                                     billingPlanType:[RCBillingPlanType RCMonthly]
    ];
}

@end
