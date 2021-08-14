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

@import Purchases;
@import PurchasesCoreSwift;

@implementation RCPackageAPI

+ (void)checkAPI {

    RCPackage *p = [[RCPackage alloc] initWithIdentifier:@"" packageType:RCPackageTypeAnnual product:[[SKProduct alloc] init] offeringIdentifier:@""];
    NSString *i = p.identifier;
    RCPackageType t = p.packageType;
    SKProduct *prod = p.product;
    NSString *lps = p.localizedPriceString;
    NSString *lips = p.localizedIntroductoryPriceString;

    NSLog(p, i, t, prod, lps, lips);

}

@end
