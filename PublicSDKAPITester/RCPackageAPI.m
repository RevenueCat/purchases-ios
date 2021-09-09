//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCPackageAPI.m
//
//  Created by Madeline Beyl on 8/13/21.

#import "RCPackageAPI.h"

@import StoreKit;
@import RevenueCat;

@implementation RCPackageAPI

+ (void)checkAPI {
    RCPackage *p;
    RCProductDetails *pw = p.productDetails;
    NSString *i = p.identifier;
    RCPackageType t = p.packageType;
    NSString *lps = p.localizedPriceString;
    NSString *lips = p.localizedIntroductoryPriceString;

    NSLog(p, pw, i, t, lps, lips);
}

+ (void)checkEnums {
    RCPackageType type = RCPackageTypeUnknown;
    type = RCPackageTypeCustom;
    type = RCPackageTypeLifetime;
    type = RCPackageTypeAnnual;
    type = RCPackageTypeSixMonth;
    type = RCPackageTypeThreeMonth;
    type = RCPackageTypeTwoMonth;
    type = RCPackageTypeMonthly;
    type = RCPackageTypeWeekly;
}

@end
