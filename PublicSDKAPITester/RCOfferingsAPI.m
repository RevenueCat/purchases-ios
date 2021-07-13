//
//  RCOfferingsAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 7/12/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import Purchases;

#import "RCOfferingsAPI.h"

@implementation RCOfferingsAPI

+ (void)checkAPI {
    RCOfferings *o = [[RCOfferings alloc] init];
    RCOffering *of = o.current;
    NSDictionary<NSString *, RCOffering *> *a = o.all;
    of = [o offeringWithIdentifier:nil];
    of = [o objectForKeyedSubscript:@""];

    NSLog(o, of, a);
}

@end
