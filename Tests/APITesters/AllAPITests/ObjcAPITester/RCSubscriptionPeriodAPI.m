//
//  RCSubscriptionPeriodAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

#import "RCSubscriptionPeriodAPI.h"

@import RevenueCat;

@implementation RCSubscriptionPeriodAPI

+ (void)checkAPI {
    RCSubscriptionPeriod *period;

    NSInteger value = period.value;
    RCSubscriptionPeriodUnit unit = period.unit;

    NSLog(period, value, unit);
}

+ (void)checkUnitEnum {
    RCSubscriptionPeriodUnit unit = RCSubscriptionPeriodUnitDay;

    switch (unit) {
        case RCSubscriptionPeriodUnitDay:
        case RCSubscriptionPeriodUnitWeek:
        case RCSubscriptionPeriodUnitMonth:
        case RCSubscriptionPeriodUnitYear:
            break;
    }
}

@end
