//
//  RCOfferingAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 7/9/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import Purchases;
#import "RCOfferingAPI.h"

@implementation RCOfferingAPI

+ (void)checkAPI {
    RCOffering *o = [[RCOffering alloc] initWithIdentifier:@"" serverDescription:@"" availablePackages:@[]];
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
    RCPackage *ok = [o objectForKeyedSubscript:@""];

    NSLog(o, i, sd, a, l, an, s, t, tm, m, w, p, ok);
}

@end
