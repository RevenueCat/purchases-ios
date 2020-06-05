//
//  RCISOPeriodFormatter.h
//  Purchases
//
//  Created by Andrés Boedo on 5/26/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "RCISOPeriodFormatter.h"


API_AVAILABLE(ios(11.2), macos(10.13.2), tvos(11.2))
@implementation RCISOPeriodFormatter

- (NSString *)stringFromProductSubscriptionPeriod:(SKProductSubscriptionPeriod *)period {
    NSString *unitString = [self periodFromUnit:period.unit];
    return [NSString stringWithFormat:@"P%@%@", @(period.numberOfUnits), unitString];
}

- (NSString *)periodFromUnit:(SKProductPeriodUnit)subscriptionPeriodUnit {
    switch (subscriptionPeriodUnit) {
        case SKProductPeriodUnitDay:
            return @"D";
        case SKProductPeriodUnitWeek:
            return @"W";
        case SKProductPeriodUnitMonth:
            return @"M";
        case SKProductPeriodUnitYear:
            return @"Y";
    }
}

@end
