//
//  RCIntroEligibility.m
//  Purchases
//
//  Created by Jacob Eiting on 2/11/18.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCIntroEligibility.h"

@interface RCIntroEligibility ()

@property (nonatomic) RCIntroEligibityStatus status;

@end

@implementation RCIntroEligibility

- (instancetype)initWithEligibilityStatus:(RCIntroEligibityStatus)status
{
    if (self = [super init]) {
        self.status = status;
    }
    return self;
}

- (NSString *)description
{
    switch (self.status) {
        case RCIntroEligibityStatusEligible:
            return @"Eligible for trial or introductory price.";
        case RCIntroEligibityStatusIneligible:
            return @"Not eligible for trial or introductory price.";
        case RCIntroEligibityStatusUnknown:
        default:
            return @"Status indeterminate. You may need to assign the subscription group in the RevenueCat web interface.";
    }
}

@end
