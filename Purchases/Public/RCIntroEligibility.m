//
//  RCIntroEligibility.m
//  Purchases
//
//  Created by Jacob Eiting on 2/11/18.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCIntroEligibility.h"

@interface RCIntroEligibility ()

@property (nonatomic) RCIntroEligibilityStatus status;

@end

@implementation RCIntroEligibility

- (instancetype)initWithEligibilityStatus:(RCIntroEligibilityStatus)status
{
    if (self = [super init]) {
        self.status = status;
    }
    return self;
}

- (NSString *)description
{
    switch (self.status) {
        case RCIntroEligibilityStatusEligible:
            return @"Eligible for trial or introductory price.";
        case RCIntroEligibilityStatusIneligible:
            return @"Not eligible for trial or introductory price.";
        case RCIntroEligibilityStatusUnknown:
        default:
            return @"Status indeterminate. You may need to assign the subscription group in the RevenueCat web interface.";
    }
}

@end
