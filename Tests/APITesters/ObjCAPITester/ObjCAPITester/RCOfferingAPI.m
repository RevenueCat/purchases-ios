//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCOfferingAPI.m
//
//  Created by Joshua Liebowitz on 7/9/21.
//

@import RevenueCat;
#import "RCOfferingAPI.h"

@implementation RCOfferingAPI

+ (void)checkAPI {
    RCOffering *o = nil; // No public initializer.
    NSString *i = o.identifier;
    NSString *sd = o.serverDescription;
    NSArray<RCPackage *> *a = o.availablePackages;
    RCPackage *l = o.lifetime;
    RCPackage *an = o.annual;
    RCPackage *s = o.sixMonth;
    RCPackage *t = o.threeMonth;
    RCPackage *tm = o.twoMonth;
    RCPackage *m = o.monthly;
    RCPackage *w = o.weekly;
    RCPackage *p = [o packageWithIdentifier:nil];
    p = [o packageWithIdentifier:@""];
    RCPackage *ok = [o objectForKeyedSubscript:@""];

    NSLog(o, i, sd, a, l, an, s, t, tm, m, w, p, ok);
}

@end
