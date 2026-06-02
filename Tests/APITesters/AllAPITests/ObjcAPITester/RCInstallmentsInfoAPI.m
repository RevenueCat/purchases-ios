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

    NSInteger commitmentInstallmentsCount __unused = installmentsInfo.commitmentInstallmentsCount;
    RCSubscriptionPeriod *commitmentInstallmentPeriod __unused = installmentsInfo.commitmentInstallmentPeriod;
    NSDecimal installmentBillingPrice __unused = installmentsInfo.installmentBillingPrice;
    NSString *installmentBillingDisplayPrice __unused = installmentsInfo.installmentBillingDisplayPrice;
    RCSubscriptionPeriod *commitmentTotalPeriod __unused = installmentsInfo.commitmentTotalPeriod;
    NSDecimal commitmentTotalPrice __unused = installmentsInfo.commitmentTotalPrice;
    NSString *commitmentTotalDisplayPrice __unused = installmentsInfo.commitmentTotalDisplayPrice;
    RCBillingPlanType *billingPlanType __unused = installmentsInfo.billingPlanType;
}

+ (void)checkInit {
    RCSubscriptionPeriod *commitmentTotalPeriod;
    RCSubscriptionPeriod *commitmentInstallmentPeriod;

    RCInstallmentsInfo *installmentsInfo __unused = [[RCInstallmentsInfo alloc]
                                                     initWithCommitmentInstallmentsCount:12
                                                     commitmentInstallmentPeriod:commitmentInstallmentPeriod
                                                     installmentBillingPrice:[[NSDecimalNumber alloc] initWithInt:10].decimalValue
                                                     installmentBillingDisplayPrice:@"$10.00"
                                                     commitmentTotalPeriod:commitmentTotalPeriod
                                                     commitmentTotalPrice:[[NSDecimalNumber alloc] initWithInt:100].decimalValue
                                                     commitmentTotalDisplayPrice:@"$100.00"
                                                     billingPlanType:[RCBillingPlanType RCMonthly]
    ];
}

@end
