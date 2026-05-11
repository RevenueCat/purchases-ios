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
    RCSubscriptionPeriod *commitmentTotalPeriod __unused = installmentsInfo.commitmentTotalPeriod;
    NSDecimal commitmentTotalPrice __unused = installmentsInfo.commitmentTotalPrice;
    NSString *commitmentTotalDisplayPrice __unused = installmentsInfo.commitmentTotalDisplayPrice;
    NSDecimal installmentBillingPrice __unused = installmentsInfo.installmentBillingPrice;
    NSString *installmentBillingDisplayPrice __unused = installmentsInfo.installmentBillingDisplayPrice;
}

+ (void)checkInit {
    RCSubscriptionPeriod *commitmentTotalPeriod;

    RCInstallmentsInfo *installmentsInfo __unused = [[RCInstallmentsInfo alloc]
        initWithCommitmentInstallmentsCount:12
                      commitmentTotalPeriod:commitmentTotalPeriod
                       commitmentTotalPrice:[[NSDecimalNumber alloc] initWithInt:100].decimalValue
                commitmentTotalDisplayPrice:@"$100.00"
                    installmentBillingPrice:[[NSDecimalNumber alloc] initWithInt:10].decimalValue
             installmentBillingDisplayPrice:@"$10.00"];
}

@end
